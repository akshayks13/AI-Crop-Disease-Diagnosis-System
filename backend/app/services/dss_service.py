"""
DSS Service - Decision Support System for crop disease advisory.

Ported from ml_models/DSS/dss_engine.py to work as a backend service.
Uses plain Python (csv module) instead of pandas for lighter dependencies.
"""
import csv
import datetime
import os
from typing import Dict, Any, Optional, List, Tuple
import logging

logger = logging.getLogger(__name__)

# Path to DSS CSV data files (relative to this module)
_DATA_DIR = os.path.join(os.path.dirname(__file__), "dss_data")


def _load_csv(filename: str) -> List[Dict[str, str]]:
    """Load a CSV file and return list of row dicts."""
    filepath = os.path.join(_DATA_DIR, filename)
    with open(filepath, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        return list(reader)


class DSSService:
    """
    Decision Support System for generating crop disease advisories.

    Uses crop_table, disease_table, and advisory_table CSV data to:
    - Look up disease type from crop + disease name
    - Compute risk score from weather + farmer inputs
    - Return treatment options, irrigation advice, crop rotation advice
    """

    def __init__(self):
        """Load CSV data at init."""
        self.crop_rows = _load_csv("crop_table.csv")
        self.disease_rows = _load_csv("disease_table.csv")
        self.advisory_rows = _load_csv("advisory_table.csv")
        logger.info("DSSService initialized with %d crops, %d diseases, %d advisory rows",
                     len(self.crop_rows), len(self.disease_rows), len(self.advisory_rows))

    # ------------------------------------------------------------------
    # Label parsing
    # ------------------------------------------------------------------
    @staticmethod
    def parse_label(label: str) -> Tuple[str, str]:
        """
        Parse a TFLite label like 'apple_apple_scab' into (crop, disease).

        The label format from labels.txt is: <crop>_<disease_name>
        But we also have special formats:
        - 'healthy_<crop>'  → (crop, 'healthy')
        - 'diseased_<crop>' → (crop, 'diseased')

        The crop name matches crop_table.csv crop_name.
        The disease name matches disease_table.csv disease_name.
        """
        parts = label.lower().split("_")

        if not parts:
            return ("unknown", "unknown")

        if parts[0] == "healthy":
            # healthy_apple → crop=apple, disease=healthy
            crop = "_".join(parts[1:])
            return (crop, "healthy")

        if parts[0] == "diseased":
            # diseased_cucumber → crop=cucumber, disease=diseased
            crop = "_".join(parts[1:])
            return (crop, "diseased")

        # For 'apple_apple_scab': need to find longest matching crop prefix
        # Known crops from the CSV
        known_crops = {
            "apple", "bean", "bell_pepper", "cherry", "corn", "cotton",
            "cucumber", "grape", "groundnut", "guava", "lemon", "peach",
            "potato", "pumpkin", "rice", "strawberry", "sugarcane", "tomato", "wheat"
        }

        # Try longest crop prefix first (e.g. bell_pepper before bell)
        for length in range(len(parts), 0, -1):
            candidate_crop = "_".join(parts[:length])
            if candidate_crop in known_crops:
                disease = "_".join(parts[length:]) if length < len(parts) else "unknown"
                return (candidate_crop, disease)

        # Fallback: first part is crop, rest is disease
        return (parts[0], "_".join(parts[1:]) if len(parts) > 1 else "unknown")

    # ------------------------------------------------------------------
    # Season detection
    # ------------------------------------------------------------------
    @staticmethod
    def get_current_season() -> str:
        """Return current Indian agricultural season."""
        month = datetime.datetime.now().month
        if 6 <= month <= 10:
            return "Kharif"
        elif month >= 11 or month <= 3:
            return "Rabi"
        else:
            return "Zaid"

    # ------------------------------------------------------------------
    # Disease type lookup
    # ------------------------------------------------------------------
    def get_disease_type(self, crop_name: str, disease_name: str) -> str:
        """Look up disease_type from crop + disease name using CSV data."""
        # Find crop_id
        crop_id = None
        for row in self.crop_rows:
            if row["crop_name"] == crop_name:
                crop_id = row["crop_id"]
                break

        if crop_id is None:
            raise ValueError(f"Crop '{crop_name}' not found in crop table")

        # Find disease type
        for row in self.disease_rows:
            if row["crop_id"] == crop_id and row["disease_name"] == disease_name:
                return row["disease_type"]

        raise ValueError(f"Disease '{disease_name}' not found for crop '{crop_name}'")

    # ------------------------------------------------------------------
    # Advisory row lookup
    # ------------------------------------------------------------------
    def _get_advisory_row(self, disease_type: str) -> Dict[str, str]:
        """Find the advisory row for a disease_type."""
        for row in self.advisory_rows:
            if row["disease_type"] == disease_type:
                return row
        raise ValueError(f"No advisory data for disease type '{disease_type}'")

    # ------------------------------------------------------------------
    # Risk calculation
    # ------------------------------------------------------------------
    def compute_risk(
        self,
        disease_type: str,
        weather: Dict[str, Any],
        farmer_answers: Dict[str, Any],
    ) -> Tuple[float, str, str]:
        """
        Compute risk score based on disease type, weather, and farmer inputs.

        Returns: (risk_score 0-1, risk_level, current_season)
        """
        advisory = self._get_advisory_row(disease_type)

        humidity = weather.get("humidity", 50)
        temperature = weather.get("temperature", 25)

        # Weather factors
        humidity_threshold = float(advisory["humidity_threshold"])
        if humidity > humidity_threshold:
            humidity_factor = 1
        elif humidity > 60:
            humidity_factor = 0.5
        else:
            humidity_factor = 0

        temp_min = float(advisory["temp_min"])
        temp_max = float(advisory["temp_max"])
        if temp_min <= temperature <= temp_max:
            temperature_factor = 1
        else:
            temperature_factor = 0.3

        # Farmer input factors
        irrigation_map = {"Low": 0.2, "Moderate": 0.5, "Frequent": 1}
        irrigation_factor = irrigation_map.get(
            farmer_answers.get("irrigation", "Moderate"), 0.5
        )

        waterlogged_factor = 1 if farmer_answers.get("waterlogged", False) else 0
        fertilizer_factor = 0.8 if farmer_answers.get("fertilizer_recent", False) else 0.4
        first_cycle_factor = 0.3 if farmer_answers.get("first_cycle", True) else 0.7

        # Base risk
        base_risk = (
            0.35 * humidity_factor
            + 0.20 * irrigation_factor
            + 0.15 * temperature_factor
            + 0.15 * waterlogged_factor
            + 0.10 * fertilizer_factor
            + 0.05 * first_cycle_factor
        )

        # Season multiplier
        current_season = self.get_current_season()
        season_trigger = advisory["season_trigger"]
        season_multiplier = float(advisory["season_multiplier"])

        if season_trigger == current_season:
            final_risk = base_risk * season_multiplier
        else:
            final_risk = base_risk

        final_risk = min(final_risk, 1.0)

        if final_risk > 0.7:
            risk_level = "High"
        elif final_risk > 0.4:
            risk_level = "Moderate"
        else:
            risk_level = "Low"

        return round(final_risk, 2), risk_level, current_season

    # ------------------------------------------------------------------
    # Main recommendation generator
    # ------------------------------------------------------------------
    def generate_recommendation(
        self,
        disease_label: str,
        weather: Optional[Dict[str, Any]] = None,
        farmer_answers: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        """
        Generate a full DSS recommendation from a TFLite disease label.

        Args:
            disease_label: Raw TFLite label e.g. 'apple_apple_scab'
            weather: {'temperature': float, 'humidity': float}
            farmer_answers: {'irrigation': str, 'waterlogged': bool,
                             'fertilizer_recent': bool, 'first_cycle': bool}

        Returns:
            Full advisory dict with risk score, treatment options, advice.
        """
        if weather is None:
            weather = {"temperature": 25, "humidity": 60}
        if farmer_answers is None:
            farmer_answers = {}

        crop_name, disease_name = self.parse_label(disease_label)

        # Handle healthy / diseased special cases
        if disease_name == "healthy":
            return {
                "crop": crop_name,
                "disease": "healthy",
                "disease_type": "Healthy",
                "season": self.get_current_season(),
                "risk_score": 0.0,
                "risk_level": "None",
                "treatment_options": {
                    "chemical": {"name": "None", "dosage": "None"},
                    "organic": {"name": "None", "dosage": "None"},
                },
                "irrigation_advice": "Maintain regular monitoring",
                "crop_rotation_advice": "Practice crop rotation annually to prevent soil fatigue",
                "explanation": f"Your {crop_name} plant appears healthy. No treatment needed.",
            }

        if disease_name == "diseased":
            # Generic diseased label – treat as Fungal fallback
            return self._generic_diseased_response(crop_name, weather, farmer_answers)

        try:
            disease_type = self.get_disease_type(crop_name, disease_name)
        except ValueError:
            return self._generic_diseased_response(crop_name, weather, farmer_answers)

        advisory = self._get_advisory_row(disease_type)

        risk_score, risk_level, season = self.compute_risk(
            disease_type, weather, farmer_answers
        )

        explanation = (
            f"Current season is {season}. "
            f"Humidity is {weather.get('humidity', 'N/A')}% and temperature is "
            f"{weather.get('temperature', 'N/A')}°C. "
            f"Irrigation level is {farmer_answers.get('irrigation', 'Moderate')}."
        )

        return {
            "crop": crop_name,
            "disease": disease_name,
            "disease_type": disease_type,
            "season": season,
            "risk_score": risk_score,
            "risk_level": risk_level,
            "treatment_options": {
                "chemical": {
                    "name": advisory["chemical_name"],
                    "dosage": advisory["chemical_dosage"],
                },
                "organic": {
                    "name": advisory["organic_name"],
                    "dosage": advisory["organic_dosage"],
                },
            },
            "irrigation_advice": advisory["irrigation_advice"],
            "crop_rotation_advice": advisory["crop_rotation_advice"],
            "explanation": explanation,
        }

    # ------------------------------------------------------------------
    def _generic_diseased_response(
        self, crop_name: str, weather: Dict, farmer_answers: Dict
    ) -> Dict[str, Any]:
        """Fallback advisory for unknown / generic 'diseased' labels."""
        try:
            advisory = self._get_advisory_row("Fungal")
            risk_score, risk_level, season = self.compute_risk(
                "Fungal", weather, farmer_answers
            )
        except ValueError:
            season = self.get_current_season()
            risk_score, risk_level = 0.5, "Moderate"
            advisory = {
                "chemical_name": "Consult an expert",
                "chemical_dosage": "N/A",
                "organic_name": "Neem oil",
                "organic_dosage": "3ml per liter water",
                "irrigation_advice": "Reduce overhead irrigation",
                "crop_rotation_advice": "Rotate with non-host crops",
            }

        return {
            "crop": crop_name,
            "disease": "unknown",
            "disease_type": "Fungal (suspected)",
            "season": season,
            "risk_score": risk_score,
            "risk_level": risk_level,
            "treatment_options": {
                "chemical": {
                    "name": advisory["chemical_name"],
                    "dosage": advisory["chemical_dosage"],
                },
                "organic": {
                    "name": advisory["organic_name"],
                    "dosage": advisory["organic_dosage"],
                },
            },
            "irrigation_advice": advisory["irrigation_advice"],
            "crop_rotation_advice": advisory["crop_rotation_advice"],
            "explanation": f"Disease could not be precisely matched for {crop_name}. "
                          f"Showing general fungal treatment recommendations.",
        }


# Singleton
_dss_service: Optional[DSSService] = None


def get_dss_service() -> DSSService:
    """Get or create DSS service instance."""
    global _dss_service
    if _dss_service is None:
        _dss_service = DSSService()
    return _dss_service

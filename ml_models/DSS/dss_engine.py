
import pandas as pd
import datetime


class DSS:
    def __init__(self):
        self.crop_df = pd.read_csv(r"ml_models\DSS\data\crop_table.csv")
        self.disease_df = pd.read_csv(r"ml_models\DSS\data\disease_table.csv")
        self.advisory_df = pd.read_csv(r"ml_models\DSS\data\advisory_table.csv")

    # -------------------------
    # Season Detection
    # -------------------------
    def get_current_season(self):
        month = datetime.datetime.now().month

        if 6 <= month <= 10:
            return "Kharif"
        elif month >= 11 or month <= 3:
            return "Rabi"
        else:
            return "Zaid"

    # -------------------------
    # Get Disease Type
    # -------------------------
    def get_disease_type(self, crop_name, disease_name):
        crop_row = self.crop_df[self.crop_df["crop_name"] == crop_name]
        if crop_row.empty:
            raise ValueError("Invalid crop name")

        crop_id = crop_row.iloc[0]["crop_id"]

        disease_row = self.disease_df[
            (self.disease_df["crop_id"] == crop_id) &
            (self.disease_df["disease_name"] == disease_name)
        ]

        if disease_row.empty:
            raise ValueError("Disease not found for this crop")

        return disease_row.iloc[0]["disease_type"]

    # -------------------------
    # Risk Calculation
    # -------------------------
    def compute_risk(self, disease_type, weather, farmer_answers):
        advisory_row = self.advisory_df[
            self.advisory_df["disease_type"] == disease_type
        ].iloc[0]

        humidity = weather["humidity"]
        temperature = weather["temperature"]

        # -------------------------
        # Weather Factors
        # -------------------------
        if humidity > advisory_row["humidity_threshold"]:
            humidity_factor = 1
        elif humidity > 60:
            humidity_factor = 0.5
        else:
            humidity_factor = 0

        if advisory_row["temp_min"] <= temperature <= advisory_row["temp_max"]:
            temperature_factor = 1
        else:
            temperature_factor = 0.3

        # -------------------------
        # Farmer Input Factors
        # -------------------------
        irrigation_map = {
            "Low": 0.2,
            "Moderate": 0.5,
            "Frequent": 1
        }
        irrigation_factor = irrigation_map.get(
            farmer_answers.get("irrigation", "Moderate"), 0.5
        )

        waterlogged_factor = 1 if farmer_answers.get("waterlogged", False) else 0
        fertilizer_factor = 0.8 if farmer_answers.get("fertilizer_recent", False) else 0.4
        first_cycle_factor = 0.3 if farmer_answers.get("first_cycle", True) else 0.7

        # -------------------------
        # Base Risk Calculation
        # -------------------------
        base_risk = (
            0.35 * humidity_factor +
            0.2 * irrigation_factor +
            0.15 * temperature_factor +
            0.15 * waterlogged_factor +
            0.1 * fertilizer_factor +
            0.05 * first_cycle_factor
        )

        # -------------------------
        # Season Multiplier
        # -------------------------
        current_season = self.get_current_season()
        season_trigger = advisory_row["season_trigger"]
        season_multiplier = advisory_row["season_multiplier"]

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
    
    # -------------------------
    # Generate Recommendation
    # -------------------------
    def generate_recommendation(self, crop_name, disease_name, weather, farmer_answers):
        disease_type = self.get_disease_type(crop_name, disease_name)

        advisory_row = self.advisory_df[
            self.advisory_df["disease_type"] == disease_type
        ].iloc[0]

        risk_score, risk_level, season = self.compute_risk(
            disease_type, weather, farmer_answers
        )

        explanation = (
            f"Current season is {season}. "
            f"Humidity is {weather['humidity']}% and temperature is "
            f"{weather['temperature']}°C. "
            f"Irrigation level is {farmer_answers.get('irrigation', 'Moderate')}."
        )

        result = {
            "crop": crop_name,
            "disease": disease_name,
            "disease_type": disease_type,
            "season": season,
            "risk_score": risk_score,
            "risk_level": risk_level,
            "treatment_options": {
                "chemical": {
                    "name": advisory_row["chemical_name"],
                    "dosage": advisory_row["chemical_dosage"]
                },
                "organic": {
                    "name": advisory_row["organic_name"],
                    "dosage": advisory_row["organic_dosage"]
                }
            },
            "irrigation_advice": advisory_row["irrigation_advice"],
            "crop_rotation_advice": advisory_row["crop_rotation_advice"],
            "explanation": explanation
        }

        return result
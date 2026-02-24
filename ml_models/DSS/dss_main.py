from dss_engine import DSS
import json


# ----------------------------------------
# WEATHER PLACEHOLDER (Teammate will replace this)
# ----------------------------------------
WEATHER_DATA = {
    "temperature": 28,   # Placeholder value
    "humidity": 75       # Placeholder value
}

# Akshay replace this with...
# WEATHER_DATA = get_weather_from_api()


def get_yes_no_input(prompt):
    print(prompt)
    print("1. Yes")
    print("2. No")
    print("Press Enter to skip (default = No)")
    choice = input("Select (1/2): ").strip()

    if choice == "1":
        return True
    return False


def get_farmer_input():
    print("\n--- Farmer Input Section ---")

    print("\nIrrigation level options:")
    print("1. Low")
    print("2. Moderate")
    print("3. Frequent")
    print("Press Enter to skip (default = Moderate)")

    irrigation_choice = input("Select irrigation level (1/2/3): ").strip()

    irrigation_map = {
        "1": "Low",
        "2": "Moderate",
        "3": "Frequent"
    }

    irrigation = irrigation_map.get(irrigation_choice, "Moderate")

    waterlogged = get_yes_no_input(
        "\nHas the field been waterlogged recently?"
    )

    fertilizer_recent = get_yes_no_input(
        "\nWas fertilizer applied recently?"
    )

    first_cycle = get_yes_no_input(
        "\nIs this the first crop cycle in this soil?"
    )

    return {
        "irrigation": irrigation,
        "waterlogged": waterlogged,
        "fertilizer_recent": fertilizer_recent,
        "first_cycle": first_cycle
    }


def main():
    dss = DSS()

    print("\n=== AI Crop Advisory System ===\n")

    crop = input("Enter crop name (e.g., tomato): ").strip().lower()
    disease = input("Enter disease name (e.g., early_blight): ").strip().lower()

    weather = WEATHER_DATA  # Using placeholder

    farmer_answers = get_farmer_input()

    try:
        output = dss.generate_recommendation(
            crop_name=crop,
            disease_name=disease,
            weather=weather,
            farmer_answers=farmer_answers
        )

        print("\n--- Advisory Result ---\n")
        print(json.dumps(output, indent=4))

    except Exception as e:
        print("\nError:", e)


if __name__ == "__main__":
    main()
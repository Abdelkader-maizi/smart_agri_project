from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from typing import Optional, Literal
import joblib
import numpy as np

app = FastAPI(title="Smart Farming AI Service", version="2.0")

# ---------------------------------------------------------------------------
# Load crop recommendation model (existing)
# ---------------------------------------------------------------------------
try:
    model = joblib.load("model/model.pkl")
except Exception as e:
    model = None
    print(f"Warning: Could not load model.pkl — {e}")


# ===========================================================================
# SCHEMAS
# ===========================================================================

class CropData(BaseModel):
    N: float
    P: float
    K: float
    temperature: float
    humidity: float
    ph: float
    rainfall: float


class IrrigationInput(BaseModel):
    crop_name: str = Field(..., example="wheat")
    water_need: Literal["low", "medium", "high"] = Field(
        ..., description="Crop water need from the crops table"
    )
    soil_type: str = Field(..., example="clay")
    temperature: float = Field(..., description="°C")
    humidity: float = Field(..., description="% relative humidity")
    rainfall: float = Field(..., description="mm of recent rainfall")
    farm_area_hectares: Optional[float] = Field(1.0, description="Farm size in hectares")


class WeatherAlertInput(BaseModel):
    farm_id: int
    temperature: float = Field(..., description="°C")
    wind_speed: float = Field(..., description="km/h")
    humidity: float = Field(..., description="% relative humidity")
    rainfall: float = Field(..., description="mm")


class YieldInput(BaseModel):
    crop_name: str = Field(..., example="wheat")
    season: Literal["summer", "winter", "spring", "autumn", "all-year"]
    nitrogen: float = Field(..., description="kg/ha")
    phosphorus: float = Field(..., description="kg/ha")
    potassium: float = Field(..., description="kg/ha")
    ph: float
    temperature: float = Field(..., description="°C average")
    humidity: float = Field(..., description="% average")
    rainfall: float = Field(..., description="mm total")
    farm_area_hectares: Optional[float] = Field(1.0)


# ===========================================================================
# HELPERS
# ===========================================================================

# Base daily water need (mm/day) per water_need level
WATER_NEED_BASE = {
    "low": 2.0,
    "medium": 4.5,
    "high": 7.0,
}

# Soil retention factor — clay retains more, sandy drains fast
SOIL_RETENTION = {
    "clay": 0.75,
    "loam": 1.0,
    "sandy": 1.35,
    "silt": 0.90,
    "sandy loam": 1.20,
    "clay loam": 0.85,
}

# Rough base yield (tons/hectare) per crop — used as starting point
CROP_BASE_YIELD = {
    "wheat": 3.5,
    "rice": 4.5,
    "maize": 5.0,
    "corn": 5.0,
    "potato": 20.0,
    "tomato": 35.0,
    "cotton": 1.8,
    "sugarcane": 60.0,
    "soybean": 2.5,
    "barley": 3.0,
    "chickpea": 1.2,
    "lentil": 1.0,
    "mungbean": 1.0,
    "blackgram": 1.0,
    "kidneybeans": 1.5,
    "pigeonpeas": 1.2,
    "mothbeans": 0.8,
    "muskmelon": 12.0,
    "watermelon": 25.0,
    "grapes": 8.0,
    "mango": 7.0,
    "banana": 30.0,
    "pomegranate": 10.0,
    "apple": 12.0,
    "orange": 15.0,
    "papaya": 25.0,
    "coconut": 8.0,
    "jute": 2.5,
    "coffee": 0.8,
}


def _clamp(value, min_val, max_val):
    return max(min_val, min(max_val, value))


# ===========================================================================
# EXISTING ENDPOINT — crop recommendation
# ===========================================================================

@app.get("/")
def home():
    return {"message": "Smart Farming AI Service is running", "version": "2.0"}


@app.post("/predict")
def predict(data: CropData):
    if model is None:
        raise HTTPException(status_code=503, detail="ML model not loaded")
    try:
        input_features = np.array([[
            data.N, data.P, data.K,
            data.temperature, data.humidity,
            data.ph, data.rainfall
        ]])
        prediction = model.predict(input_features)[0]
        probabilities = model.predict_proba(input_features)[0]
        confidence = max(probabilities)
        
        status_message = "High confidence prediction."
        if confidence < 0.70:
            status_message = "Low confidence prediction. Consult a local agricultural expert."
            
        return {
            "recommended_crop": prediction,
            "confidence_score": round(confidence, 2),
            "message": status_message
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ===========================================================================
# NEW ENDPOINT 1 — Smart Irrigation
# ===========================================================================

@app.post("/irrigation")
def irrigation_recommendation(data: IrrigationInput):
    """
    Returns daily irrigation amount (liters/hectare) and a weekly schedule
    based on crop water need, soil type, and current weather conditions.
    """
    # 1. Base daily water need from crop level
    base_mm = WATER_NEED_BASE.get(data.water_need, 4.5)

    # 2. Adjust for soil drainage (sandy soil needs more water)
    soil_key = data.soil_type.lower()
    retention_factor = SOIL_RETENTION.get(soil_key, 1.0)
    adjusted_mm = base_mm * retention_factor

    # 3. Temperature stress factor (high temp = more evapotranspiration)
    if data.temperature > 35:
        temp_factor = 1.30
    elif data.temperature > 30:
        temp_factor = 1.15
    elif data.temperature > 25:
        temp_factor = 1.05
    elif data.temperature < 10:
        temp_factor = 0.70
    elif data.temperature < 15:
        temp_factor = 0.85
    else:
        temp_factor = 1.0

    # 4. Humidity factor (high humidity = less evaporation)
    if data.humidity > 80:
        humidity_factor = 0.85
    elif data.humidity > 60:
        humidity_factor = 0.95
    elif data.humidity < 30:
        humidity_factor = 1.20
    else:
        humidity_factor = 1.0

    # 5. Subtract effective rainfall (only 70% of rainfall is usable)
    effective_rainfall = data.rainfall * 0.70
    net_mm = max(0.0, (adjusted_mm * temp_factor * humidity_factor) - effective_rainfall)

    # 6. Convert mm/day to liters/hectare (1 mm = 10,000 L/ha)
    liters_per_hectare_day = round(net_mm * 10000, 1)
    total_liters = round(liters_per_hectare_day * data.farm_area_hectares, 1)

    # 7. Build weekly schedule (irrigate on days when need is high)
    # Simple rule: skip days if rainfall was significant
    if net_mm == 0:
        schedule = ["No irrigation needed — recent rainfall is sufficient"] * 7
        irrigate_days = 0
    elif net_mm < 2:
        irrigate_days = 3
        schedule = [
            "Irrigate" if i in [1, 3, 5] else "Skip"
            for i in range(1, 8)
        ]
        schedule = [f"Day {i+1}: {s}" for i, s in enumerate(schedule)]
    elif net_mm < 5:
        irrigate_days = 5
        schedule = [
            "Irrigate" if i not in [3, 6] else "Skip"
            for i in range(1, 8)
        ]
        schedule = [f"Day {i+1}: {s}" for i, s in enumerate(schedule)]
    else:
        irrigate_days = 7
        schedule = [f"Day {i+1}: Irrigate" for i in range(7)]

    # 8. Determine irrigation method recommendation
    if data.water_need == "high" or data.soil_type.lower() == "sandy":
        method = "drip"
        method_reason = "Drip irrigation recommended to minimize evaporation loss"
    elif data.water_need == "low":
        method = "sprinkler"
        method_reason = "Sprinkler system suitable for low water-need crops"
    else:
        method = "furrow"
        method_reason = "Furrow irrigation appropriate for this soil and crop type"

    return {
        "crop": data.crop_name,
        "daily_water_need_mm": round(net_mm, 2),
        "liters_per_hectare_per_day": liters_per_hectare_day,
        "total_liters_per_day": total_liters,
        "irrigate_days_per_week": irrigate_days,
        "weekly_schedule": schedule,
        "recommended_method": method,
        "method_reason": method_reason,
        "notes": {
            "effective_rainfall_mm": round(effective_rainfall, 2),
            "soil_retention_factor": retention_factor,
            "temperature_factor": temp_factor,
            "humidity_factor": humidity_factor,
        }
    }


# ===========================================================================
# NEW ENDPOINT 2 — Weather Alerts
# ===========================================================================

@app.post("/alerts")
def check_weather_alerts(data: WeatherAlertInput):
    """
    Evaluates current weather readings against threshold rules and returns
    a list of alerts matching the alerts table schema (type + message).
    Designed to be called after inserting a row into weather_data.
    """
    triggered = []

    # --- FROST alert ---
    if data.temperature <= 2:
        severity = "critical" if data.temperature <= 0 else "warning"
        triggered.append({
            "farm_id": data.farm_id,
            "type": "frost",
            "severity": severity,
            "message": (
                f"Frost risk detected. Temperature is {data.temperature}°C. "
                "Protect sensitive crops immediately — cover plants or activate "
                "frost protection irrigation to create an insulating ice layer."
            ),
        })

    # --- EXTREME HEAT alert ---
    if data.temperature >= 38:
        severity = "critical" if data.temperature >= 42 else "warning"
        triggered.append({
            "farm_id": data.farm_id,
            "type": "heat",
            "severity": severity,
            "message": (
                f"Extreme heat alert. Temperature is {data.temperature}°C. "
                "Increase irrigation frequency, apply mulch to retain soil moisture, "
                "and consider shading for heat-sensitive crops."
            ),
        })
    elif data.temperature >= 35:
        triggered.append({
            "farm_id": data.farm_id,
            "type": "heat",
            "severity": "info",
            "message": (
                f"High temperature warning. Temperature is {data.temperature}°C. "
                "Monitor crops for heat stress and ensure adequate soil moisture."
            ),
        })

    # --- STRONG WIND alert ---
    if data.wind_speed >= 60:
        severity = "critical" if data.wind_speed >= 80 else "warning"
        triggered.append({
            "farm_id": data.farm_id,
            "type": "wind",
            "severity": severity,
            "message": (
                f"Strong wind alert. Wind speed is {data.wind_speed} km/h. "
                "Secure greenhouse structures, support tall crops with stakes, "
                "and avoid spraying pesticides or fertilizers until winds subside."
            ),
        })
    elif data.wind_speed >= 40:
        triggered.append({
            "farm_id": data.farm_id,
            "type": "wind",
            "severity": "info",
            "message": (
                f"Moderate wind advisory. Wind speed is {data.wind_speed} km/h. "
                "Check young plants and trellised crops for wind damage."
            ),
        })

    # --- HEAVY RAIN / FLOOD risk alert ---
    if data.rainfall >= 50:
        triggered.append({
            "farm_id": data.farm_id,
            "type": "flood",
            "severity": "warning",
            "message": (
                f"Heavy rainfall detected: {data.rainfall} mm. "
                "Check drainage systems, watch for waterlogging in low-lying fields, "
                "and delay any soil-disturbing operations."
            ),
        })

    # --- DROUGHT alert (low rainfall + high temp + low humidity) ---
    if data.rainfall == 0 and data.temperature >= 30 and data.humidity < 30:
        triggered.append({
            "farm_id": data.farm_id,
            "type": "drought",
            "severity": "warning",
            "message": (
                f"Drought stress conditions: no rainfall, {data.temperature}°C, "
                f"{data.humidity}% humidity. Activate irrigation immediately and "
                "apply mulch to conserve soil moisture."
            ),
        })

    return {
        "farm_id": data.farm_id,
        "total_alerts": len(triggered),
        "alerts": triggered,
        "status": "clear" if not triggered else "alerts_triggered",
    }


# ===========================================================================
# NEW ENDPOINT 3 — Yield Prediction
# ===========================================================================

@app.post("/yield")
def yield_prediction(data: YieldInput):
    """
    Estimates crop yield (tons/hectare) using a weighted scoring model
    based on soil nutrients, pH, weather conditions, and crop season fit.
    Returns predicted yield, confidence band, and per-factor scores.
    """
    crop_key = data.crop_name.lower()
    base_yield = CROP_BASE_YIELD.get(crop_key, 3.0)

    scores = {}

    # --- Nitrogen score (optimal 40–80 kg/ha for most crops) ---
    if 40 <= data.nitrogen <= 80:
        scores["nitrogen"] = 1.0
    elif 20 <= data.nitrogen < 40 or 80 < data.nitrogen <= 120:
        scores["nitrogen"] = 0.85
    elif data.nitrogen < 20:
        scores["nitrogen"] = 0.60
    else:
        scores["nitrogen"] = 0.75  # excess nitrogen hurts

    # --- Phosphorus score (optimal 30–60 kg/ha) ---
    if 30 <= data.phosphorus <= 60:
        scores["phosphorus"] = 1.0
    elif 15 <= data.phosphorus < 30 or 60 < data.phosphorus <= 90:
        scores["phosphorus"] = 0.85
    else:
        scores["phosphorus"] = 0.65

    # --- Potassium score (optimal 20–50 kg/ha) ---
    if 20 <= data.potassium <= 50:
        scores["potassium"] = 1.0
    elif 10 <= data.potassium < 20 or 50 < data.potassium <= 80:
        scores["potassium"] = 0.85
    else:
        scores["potassium"] = 0.65

    # --- pH score (optimal 6.0–7.5 for most crops) ---
    if 6.0 <= data.ph <= 7.5:
        scores["ph"] = 1.0
    elif 5.5 <= data.ph < 6.0 or 7.5 < data.ph <= 8.0:
        scores["ph"] = 0.85
    elif 5.0 <= data.ph < 5.5 or 8.0 < data.ph <= 8.5:
        scores["ph"] = 0.70
    else:
        scores["ph"] = 0.50

    # --- Temperature score ---
    if 20 <= data.temperature <= 30:
        scores["temperature"] = 1.0
    elif 15 <= data.temperature < 20 or 30 < data.temperature <= 35:
        scores["temperature"] = 0.85
    elif 10 <= data.temperature < 15 or 35 < data.temperature <= 38:
        scores["temperature"] = 0.70
    else:
        scores["temperature"] = 0.50

    # --- Rainfall score (optimal 100–250 mm per growing season) ---
    if 100 <= data.rainfall <= 250:
        scores["rainfall"] = 1.0
    elif 60 <= data.rainfall < 100 or 250 < data.rainfall <= 350:
        scores["rainfall"] = 0.85
    elif 30 <= data.rainfall < 60 or 350 < data.rainfall <= 500:
        scores["rainfall"] = 0.70
    else:
        scores["rainfall"] = 0.55

    # --- Season fit score ---
    season_map = {
        "summer": ["summer", "all-year"],
        "winter": ["winter", "all-year"],
        "spring": ["spring", "all-year"],
        "autumn": ["autumn", "all-year"],
        "all-year": ["summer", "winter", "spring", "autumn", "all-year"],
    }
    scores["season"] = 1.0 if data.season in season_map.get(data.season, []) else 0.75

    # --- Humidity bonus/penalty ---
    if 50 <= data.humidity <= 80:
        scores["humidity"] = 1.0
    elif 30 <= data.humidity < 50 or 80 < data.humidity <= 90:
        scores["humidity"] = 0.90
    else:
        scores["humidity"] = 0.75

    # Weighted average of all factor scores
    weights = {
        "nitrogen": 0.18,
        "phosphorus": 0.14,
        "potassium": 0.14,
        "ph": 0.16,
        "temperature": 0.16,
        "rainfall": 0.14,
        "humidity": 0.05,
        "season": 0.03,
    }
    weighted_score = sum(scores[k] * weights[k] for k in scores)

    predicted_yield = round(base_yield * weighted_score * data.farm_area_hectares, 2)

    # Confidence band: ±15% of predicted
    low = round(predicted_yield * 0.85, 2)
    high = round(predicted_yield * 1.15, 2)

    # Quality rating
    if weighted_score >= 0.90:
        quality = "excellent"
        quality_message = "Conditions are ideal. Expect strong yield."
    elif weighted_score >= 0.78:
        quality = "good"
        quality_message = "Conditions are favorable. Normal yield expected."
    elif weighted_score >= 0.65:
        quality = "moderate"
        quality_message = "Some limiting factors detected. Yield may be below average."
    else:
        quality = "poor"
        quality_message = "Multiple stress factors present. Consider improving soil nutrition or irrigation."

    # Identify the weakest factor
    weakest = min(scores, key=scores.get)
    improvement_tip = {
        "nitrogen": "Apply nitrogen-rich fertilizer (urea or ammonium nitrate).",
        "phosphorus": "Add phosphorus fertilizer (superphosphate) to improve root development.",
        "potassium": "Apply potash fertilizer to strengthen plant immunity.",
        "ph": "Adjust soil pH: add lime to raise it, sulfur to lower it.",
        "temperature": "Consider shade nets or greenhouses to moderate temperature.",
        "rainfall": "Optimize irrigation schedule to compensate for rainfall deficit or excess.",
        "humidity": "Improve ventilation or irrigation timing to regulate humidity.",
        "season": "Planting in the correct season will significantly improve yield.",
    }

    return {
        "crop": data.crop_name,
        "farm_area_hectares": data.farm_area_hectares,
        "predicted_yield_tons": predicted_yield,
        "yield_range": {
            "low_tons": low,
            "high_tons": high,
        },
        "yield_per_hectare_tons": round(base_yield * weighted_score, 2),
        "overall_score": round(weighted_score, 3),
        "quality_rating": quality,
        "quality_message": quality_message,
        "top_improvement": improvement_tip.get(weakest, "Review all soil and weather inputs."),
        "weakest_factor": weakest,
        "factor_scores": {k: round(v, 2) for k, v in scores.items()},
    }
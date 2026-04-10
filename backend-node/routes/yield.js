const router = require("express").Router();
const axios = require("axios");
const { fetchCurrentWeather } = require("../utils/weather");
const pool = require("../config/db");
const auth = require("../middleware/auth");

router.post("/", auth, async (req, res) => {
  try {
    let { farm_id, crop_name, season, nitrogen, phosphorus, potassium, ph, temperature, humidity, rainfall, farm_area_hectares } = req.body;
    
    // --- Auto-Fetch Weather if Missing and Farm ID Provided ---
    if (farm_id && (temperature === undefined || humidity === undefined || rainfall === undefined)) {
      const farmResult = await pool.query("SELECT latitude, longitude FROM farms WHERE id=$1 AND user_id=$2", [farm_id, req.user.id]);
      if (farmResult.rows.length > 0) {
        const { latitude, longitude } = farmResult.rows[0];
        try {
          const w = await fetchCurrentWeather(latitude, longitude);
          if (temperature === undefined) temperature = w.temperature;
          if (humidity === undefined) humidity = w.humidity;
          if (rainfall === undefined) rainfall = w.rainfall;
        } catch (e) {
          console.error("Failed to auto-fetch weather for yield:", e.message);
        }
      }
    }

    // validate
    if (!farm_id || !crop_name || !season || nitrogen === undefined || phosphorus === undefined || potassium === undefined || ph === undefined || temperature === undefined || humidity === undefined || rainfall === undefined) {
      return res.status(400).json({ success: false, error: "Missing required fields or weather data unavailable" });
    }

    const fastApiUrl = process.env.FASTAPI_URL || "http://localhost:8000";
    let aiResponse;
    try {
      aiResponse = await axios.post(`${fastApiUrl}/yield`, {
        crop_name, season, nitrogen: Number(nitrogen), phosphorus: Number(phosphorus), 
        potassium: Number(potassium), ph: Number(ph), temperature: Number(temperature),
        humidity: Number(humidity), rainfall: Number(rainfall), farm_area_hectares: Number(farm_area_hectares || 1.0)
      });
    } catch (axiosErr) {
      return res.status(503).json({ success: false, error: "AI service unavailable", details: axiosErr.message });
    }

    const data = aiResponse.data;
    
    // Store in DB
    await pool.query(
      `INSERT INTO yield_predictions (farm_id, crop_name, predicted_yield_tons, quality_rating) 
       VALUES ($1, $2, $3, $4)`,
      [farm_id, data.crop, data.predicted_yield_tons, data.quality_rating]
    );

    res.json({ success: true, data });
  } catch (err) {
    console.error("Yield route error:", err);
    res.status(500).json({ success: false, error: "Server error" });
  }
});

module.exports = router;

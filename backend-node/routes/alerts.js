const router = require("express").Router();
const axios = require("axios");
const { fetchCurrentWeather } = require("../utils/weather");
const { sendAlertEmail } = require("../utils/email");
const pool = require("../config/db");
const auth = require("../middleware/auth");

router.post("/", auth, async (req, res) => {
  try {
    let { farm_id, temperature, wind_speed, humidity, rainfall } = req.body;
    
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
          // wind_speed is not in fetchCurrentWeather yet, assume default if missing
          if (wind_speed === undefined) wind_speed = 10;
        } catch (e) {
          console.error("Failed to auto-fetch weather for alerts:", e.message);
        }
      }
    }

    // validate
    if (!farm_id || temperature === undefined || wind_speed === undefined || humidity === undefined || rainfall === undefined) {
      return res.status(400).json({ success: false, error: "Missing required fields or weather data unavailable" });
    }

    const fastApiUrl = process.env.FASTAPI_URL || "http://localhost:8000";
    let aiResponse;
    try {
      aiResponse = await axios.post(`${fastApiUrl}/alerts`, {
        farm_id: Number(farm_id), temperature: Number(temperature), wind_speed: Number(wind_speed),
        humidity: Number(humidity), rainfall: Number(rainfall) 
      });
    } catch (axiosErr) {
      return res.status(503).json({ success: false, error: "AI service unavailable" });
    }

    const data = aiResponse.data;
    
    // Store triggered alerts in DB
    if (data.alerts && data.alerts.length > 0) {
      const userRes = await pool.query("SELECT email, language FROM users WHERE id=$1", [req.user.id]);
      const userEmail = userRes.rows.length > 0 ? userRes.rows[0].email : null;
      const userLang = userRes.rows.length > 0 ? (userRes.rows[0].language || 'ar') : 'ar';

      for (const alert of data.alerts) {
        await pool.query(
          `INSERT INTO alerts (farm_id, type, severity, message) VALUES ($1, $2, $3, $4)`,
          [alert.farm_id, alert.type, alert.severity, alert.message]
        );
        // Only send email if a real email exists and alert severity is serious (not just Info)
        if (userEmail && (alert.severity === 'Warning' || alert.severity === 'Critical')) {
          sendAlertEmail(userEmail, userLang, alert).catch(e => console.error("Alert email dispatch failed:", e.message));
        }
      }
    }

    res.json({ success: true, data });
  } catch (err) {
    console.error("Alerts route error:", err);
    res.status(500).json({ success: false, error: "Server error" });
  }
});

module.exports = router;

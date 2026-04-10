const router = require("express").Router();
const axios = require("axios");
const { fetchCurrentWeather } = require("../utils/weather");
const pool = require("../config/db");
const auth = require("../middleware/auth");

// Helper: check that a value is a finite number within an optional range
function isValidNumber(value, min = -Infinity, max = Infinity) {
  const n = Number(value);
  return !isNaN(n) && isFinite(n) && n >= min && n <= max;
}

// Prediction and save route
router.post("/", auth, async (req, res) => {
  try {
    let { farm_id, N, P, K, temperature, humidity, ph, rainfall } = req.body;

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
          console.error("Failed to auto-fetch weather for prediction:", e.message);
        }
      }
    }

    // --- 1. Check all fields are present ---
    const fields = { N, P, K, temperature, humidity, ph, rainfall };
    const missing = Object.keys(fields).filter(k => fields[k] === undefined || fields[k] === "");
    if (missing.length > 0)
      return res.status(400).json({
        success: false,
        error: `Missing fields: ${missing.join(", ")}`,
      });

    // --- 2. Validate numeric ranges ---
    if (!isValidNumber(N, 0, 140))
      return res.status(400).json({ success: false, error: "N (Nitrogen) must be a number between 0 and 140" });
    if (!isValidNumber(P, 0, 145))
      return res.status(400).json({ success: false, error: "P (Phosphorus) must be a number between 0 and 145" });
    if (!isValidNumber(K, 0, 205))
      return res.status(400).json({ success: false, error: "K (Potassium) must be a number between 0 and 205" });
    if (!isValidNumber(temperature, -10, 55))
      return res.status(400).json({ success: false, error: "Temperature must be a number between -10 and 55°C" });
    if (!isValidNumber(humidity, 0, 100))
      return res.status(400).json({ success: false, error: "Humidity must be a number between 0 and 100%" });
    if (!isValidNumber(ph, 0, 14))
      return res.status(400).json({ success: false, error: "pH must be a number between 0 and 14" });
    if (!isValidNumber(rainfall, 0, 300))
      return res.status(400).json({ success: false, error: "Rainfall must be a number between 0 and 300mm" });

    // --- 3. Send data to FastAPI ---
    const fastApiUrl = process.env.FASTAPI_URL || "http://localhost:8000";
    let aiResponse;
    try {
      aiResponse = await axios.post(`${fastApiUrl}/predict`, {
        N: Number(N), P: Number(P), K: Number(K),
        temperature: Number(temperature),
        humidity: Number(humidity),
        ph: Number(ph),
        rainfall: Number(rainfall),
      });
    } catch (axiosErr) {
      console.error("FastAPI connection error:", axiosErr.message);
      return res.status(503).json({
        success: false,
        error: "AI prediction service is unavailable. Make sure FastAPI is running.",
      });
    }

    const recommendedCrop = aiResponse.data.recommended_crop;

    // --- 4. Save result to database ---
    await pool.query(
      `INSERT INTO crop_history 
       (user_id, n_value, p_value, k_value, temperature, humidity, ph, rainfall, recommended_crop) 
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)`,
      [req.user.id, N, P, K, temperature, humidity, ph, rainfall, recommendedCrop]
    );

    // --- 5. Return result ---
    res.json({
      success: true,
      recommendation: recommendedCrop,
      message: `Based on your soil and climate data, the best crop is: ${recommendedCrop}`,
      saved_to_db: true,
    });

  } catch (err) {
    console.error("Prediction route error:", err.message);
    res.status(500).json({
      success: false,
      error: "Unexpected server error in prediction flow",
    });
  }
});

// Get prediction history for the logged-in user
router.get("/history", auth, async (req, res) => {
  try {
    const history = await pool.query(
      "SELECT * FROM crop_history WHERE user_id=$1 ORDER BY created_at DESC LIMIT 50",
      [req.user.id]
    );

    res.json({ success: true, history: history.rows });

  } catch (err) {
    console.error("Fetch history error:", err.message);
    res.status(500).json({ success: false, error: "Server error while fetching history" });
  }
});
  
module.exports = router;
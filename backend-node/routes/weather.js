const router = require("express").Router();
const pool = require("../config/db");
const auth = require("../middleware/auth");
const { fetchCurrentWeather } = require("../utils/weather");

// GET /api/weather?farm_id=123
router.get("/", auth, async (req, res) => {
  try {
    const { farm_id, lat, lon } = req.query;
    
    let targetLat, targetLon;

    if (farm_id) {
      // Look up farm location
      const farmResult = await pool.query("SELECT latitude, longitude FROM farms WHERE id=$1 AND user_id=$2", [farm_id, req.user.id]);
      if (farmResult.rows.length === 0) {
        return res.status(404).json({ success: false, error: "Farm not found or access denied" });
      }
      targetLat = Number(farmResult.rows[0].latitude);
      targetLon = Number(farmResult.rows[0].longitude);
    } else if (lat !== undefined && lon !== undefined) {
      targetLat = Number(lat);
      targetLon = Number(lon);
    } else {
      return res.status(400).json({ success: false, error: "Must provide farm_id OR (lat and lon)" });
    }

    if (isNaN(targetLat) || isNaN(targetLon)) {
      return res.status(400).json({ success: false, error: "Invalid coordinates format" });
    }

    const weather = await fetchCurrentWeather(targetLat, targetLon);
    
    res.json({
      success: true,
      data: weather
    });

  } catch (err) {
    console.error("GET Weather error:", err.message);
    res.status(500).json({ success: false, error: err.message || "Failed to fetch weather data" });
  }
});

module.exports = router;

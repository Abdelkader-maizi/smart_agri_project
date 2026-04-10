const router = require("express").Router();
const fs = require("fs");
const path = require("path");

// Fetch 58 wilayas of Algeria
router.get("/wilayas", (req, res) => {
  try {
    const dataPath = path.join(__dirname, "../data/algeria_wilayas.json");
    if (!fs.existsSync(dataPath)) {
      return res.status(404).json({ success: false, error: "Data not found" });
    }
    const data = JSON.parse(fs.readFileSync(dataPath, "utf8"));
    // Add caching header so mobile apps cache this offline automatically
    res.setHeader('Cache-Control', 'public, max-age=86400'); // 1 day
    res.json({ success: true, wilayas: data });
  } catch (err) {
    console.error("Geo fetch error:", err);
    res.status(500).json({ success: false, error: "Server error" });
  }
});

module.exports = router;

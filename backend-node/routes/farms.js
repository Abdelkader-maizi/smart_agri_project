const router = require("express").Router();
const pool = require("../config/db");
const auth = require("../middleware/auth");

// Add farm
router.post("/", auth, async (req, res) => {
  try {
    const { name, city, latitude, longitude } = req.body;

    // Input validation
    if (!name || !city || latitude === undefined || longitude === undefined)
      return res.status(400).json({ success: false, error: "Farm name, city, latitude, and longitude are required" });

    if (isNaN(latitude) || isNaN(longitude))
      return res.status(400).json({ success: false, error: "Latitude and longitude must be valid numbers" });

    if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180)
      return res.status(400).json({ success: false, error: "Latitude or longitude out of valid range" });

    const farm = await pool.query(
      "INSERT INTO farms(user_id, name, city, latitude, longitude) VALUES($1,$2,$3,$4,$5) RETURNING *",
      [req.user.id, name, city, latitude, longitude]
    );

    res.status(201).json({ success: true, farm: farm.rows[0] });

  } catch (err) {
    console.error("Add farm error:", err.message);
    res.status(500).json({ success: false, error: "Server error while adding farm" });
  }
});

// Fetch user farms
router.get("/", auth, async (req, res) => {
  try {
    const farms = await pool.query(
      "SELECT * FROM farms WHERE user_id=$1 ORDER BY created_at DESC",
      [req.user.id]
    );

    res.json({ success: true, farms: farms.rows });

  } catch (err) {
    console.error("Fetch farms error:", err.message);
    res.status(500).json({ success: false, error: "Server error while fetching farms" });
  }
});

// Delete a farm
router.delete("/:id", auth, async (req, res) => {
  try {
    const { id } = req.params;

    // Make sure the farm belongs to this user before deleting
    const farm = await pool.query(
      "SELECT id FROM farms WHERE id=$1 AND user_id=$2",
      [id, req.user.id]
    );

    if (farm.rows.length === 0)
      return res.status(404).json({ success: false, error: "Farm not found or access denied" });

    await pool.query("DELETE FROM farms WHERE id=$1", [id]);

    res.json({ success: true, message: "Farm deleted successfully" });

  } catch (err) {
    console.error("Delete farm error:", err.message);
    res.status(500).json({ success: false, error: "Server error while deleting farm" });
  }
});

module.exports = router;
const router = require("express").Router();
const pool = require("../config/db");
const auth = require("../middleware/auth");

// Fetch logs for farmer
router.get("/", auth, async (req, res) => {
  try {
    const logs = await pool.query(
      "SELECT * FROM farmer_logs WHERE user_id=$1 ORDER BY created_at DESC",
      [req.user.id]
    );
    res.json({ success: true, logs: logs.rows });
  } catch (err) {
    console.error("Fetch logs error:", err);
    res.status(500).json({ success: false, error: "Server error" });
  }
});

// Add single log (Online)
router.post("/", auth, async (req, res) => {
  try {
    const { id, farm_id, activity_type, description, created_at } = req.body;
    
    if (!id || !farm_id || !activity_type) {
      return res.status(400).json({ success: false, error: "Missing required fields" });
    }

    const log = await pool.query(
      `INSERT INTO farmer_logs (id, user_id, farm_id, activity_type, description, created_at, synced_at)
       VALUES ($1, $2, $3, $4, $5, $6, CURRENT_TIMESTAMP)
       ON CONFLICT (id) DO NOTHING RETURNING *`,
      [id, req.user.id, farm_id, activity_type, description, created_at || new Date()]
    );

    res.status(201).json({ success: true, log: log.rows[0] || "Already synced" });
  } catch (err) {
    console.error("Add log error:", err);
    res.status(500).json({ success: false, error: "Server error" });
  }
});

// Offline Sync (Mobile pushes all unsynced data at once)
router.post("/sync", auth, async (req, res) => {
  try {
    const { offlineLogs } = req.body;

    if (!offlineLogs || !Array.isArray(offlineLogs)) {
      return res.status(400).json({ success: false, error: "offlineLogs array is required" });
    }

    let syncedCount = 0;
    
    // Process insertions in a simple loop (could be batched for massive arrays)
    for (const item of offlineLogs) {
      const { id, farm_id, activity_type, description, created_at } = item;
      
      if (!id || !farm_id || !activity_type) continue; // skip malformed

      const result = await pool.query(
        `INSERT INTO farmer_logs (id, user_id, farm_id, activity_type, description, created_at, synced_at)
         VALUES ($1, $2, $3, $4, $5, $6, CURRENT_TIMESTAMP)
         ON CONFLICT (id) DO NOTHING`,
        [id, req.user.id, farm_id, activity_type, description, created_at || new Date()]
      );

      // rowCount is 1 if inserted, 0 if conflict
      if (result.rowCount > 0) syncedCount++;
    }

    res.json({ 
      success: true, 
      message: "Sync completed", 
      total_received: offlineLogs.length,
      new_synced: syncedCount 
    });

  } catch (err) {
    console.error("Sync error:", err);
    res.status(500).json({ success: false, error: "Server error during synchronization" });
  }
});

module.exports = router;

require("dotenv").config();
const { Pool } = require("pg");
const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: process.env.DB_PASSWORD,
  port: Number(process.env.DB_PORT),
});

async function migrate() {
  try {
    console.log("Creating farmer logs tables...");
    await pool.query(`
      CREATE TABLE IF NOT EXISTS farmer_logs (
        id varchar PRIMARY KEY, -- Offline sync IDs are often UUIDs generated locally
        user_id int REFERENCES users(id) ON DELETE CASCADE,
        farm_id int REFERENCES farms(id) ON DELETE CASCADE,
        activity_type varchar, -- e.g., 'plowing', 'sowing', 'irrigation', 'harvesting', 'fertilizing'
        description text,
        created_at timestamp DEFAULT CURRENT_TIMESTAMP,
        synced_at timestamp DEFAULT CURRENT_TIMESTAMP
      );
    `);
    
    // Add language to users if it doesn't exist
    await pool.query(`
      ALTER TABLE users ADD COLUMN IF NOT EXISTS language varchar DEFAULT 'ar';
    `);

    console.log("Migration successful!");
  } catch(e) {
    console.error("Migration failed:", e);
  } finally {
    pool.end();
  }
}
migrate();

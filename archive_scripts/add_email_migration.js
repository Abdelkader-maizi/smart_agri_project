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
    console.log("Adding email columns to users table...");
    await pool.query(`
      ALTER TABLE users 
      ADD COLUMN IF NOT EXISTS email varchar UNIQUE,
      ADD COLUMN IF NOT EXISTS reset_token varchar,
      ADD COLUMN IF NOT EXISTS reset_token_expires timestamp;
    `);
    console.log("Migration successful!");
  } catch(e) {
    console.error("Migration failed:", e);
  } finally {
    pool.end();
  }
}
migrate();

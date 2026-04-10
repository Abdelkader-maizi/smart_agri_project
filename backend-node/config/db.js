const { Pool } = require("pg");

// Guard: fail fast with a clear message if env vars are missing
const required = ["DB_USER", "DB_HOST", "DB_NAME", "DB_PASSWORD", "DB_PORT"];
for (const key of required) {
  if (!process.env[key]) {
    console.error(`❌ Missing environment variable: ${key}`);
    console.error("   Make sure your .env file exists and is named correctly (.env not .eve)");
    process.exit(1);
  }
}

const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: process.env.DB_PASSWORD,  // must be a string — comes from .env
  port: Number(process.env.DB_PORT),
});

pool.connect((err, client, release) => {
  if (err) {
    return console.error("❌ Database connection failed:", err.message);
  }
  console.log("✅ Connected to smart_farming_db successfully.");
  release();
});

module.exports = pool;
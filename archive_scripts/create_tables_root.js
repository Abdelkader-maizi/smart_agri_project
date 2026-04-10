require("dotenv").config({ path: "./backend-node/.env" });
const { Pool } = require("pg");
const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: process.env.DB_PASSWORD,
  port: Number(process.env.DB_PORT),
});

async function run() {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS alerts (
        id serial PRIMARY KEY,
        farm_id int REFERENCES farms(id) ON DELETE CASCADE,
        type varchar,
        severity varchar,
        message text,
        created_at timestamp DEFAULT CURRENT_TIMESTAMP
      );
      CREATE TABLE IF NOT EXISTS irrigation_history (
        id serial PRIMARY KEY,
        farm_id int REFERENCES farms(id) ON DELETE CASCADE,
        crop_name varchar,
        daily_water_need_mm double precision,
        total_liters_per_day double precision,
        recommended_method varchar,
        created_at timestamp DEFAULT CURRENT_TIMESTAMP
      );
      CREATE TABLE IF NOT EXISTS yield_predictions (
        id serial PRIMARY KEY,
        farm_id int REFERENCES farms(id) ON DELETE CASCADE,
        crop_name varchar,
        predicted_yield_tons double precision,
        quality_rating varchar,
        created_at timestamp DEFAULT CURRENT_TIMESTAMP
      );
    `);
    console.log("Tables initialized!");
  } catch(e) {
    console.error(e);
  } finally {
    pool.end();
  }
}
run();

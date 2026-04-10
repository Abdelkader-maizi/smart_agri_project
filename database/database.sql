--- Database schema for Smart Farming Application
-- This schema includes tables for users, farms, crops, weather data, soil data, predictions, alerts, and logs.
-- The schema is designed to support a smart farming application that provides personalized recommendations based on user data and environmental conditions.

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    phone VARCHAR(20) UNIQUE,
    password TEXT,
    language VARCHAR(20) DEFAULT 'ar',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE farms (
    id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(id),
    name VARCHAR(100),
    location TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE crops (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    season VARCHAR(50),
    water_need VARCHAR(50)
);

CREATE TABLE farm_crops (
    id SERIAL PRIMARY KEY,
    farm_id INT REFERENCES farms(id),
    crop_id INT REFERENCES crops(id),
    planting_date DATE,
    expected_harvest DATE
);

CREATE TABLE weather_data (
    id SERIAL PRIMARY KEY,
    farm_id INT REFERENCES farms(id),
    temperature FLOAT,
    humidity FLOAT,
    wind_speed FLOAT,
    rainfall FLOAT,
    date DATE
);

CREATE TABLE soil_data (
    id SERIAL PRIMARY KEY,
    farm_id INT REFERENCES farms(id),
    soil_type VARCHAR(50),
    ph FLOAT,
    nitrogen FLOAT,
    phosphorus FLOAT,
    potassium FLOAT
);

CREATE TABLE predictions (
    id SERIAL PRIMARY KEY,
    farm_id INT REFERENCES farms(id),
    crop_id INT REFERENCES crops(id),
    yield_prediction FLOAT,
    irrigation_recommendation TEXT,
    best_planting_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE alerts (
    id SERIAL PRIMARY KEY,
    farm_id INT REFERENCES farms(id),
    type VARCHAR(50), -- frost, heat, wind
    message TEXT,
    alert_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE logs (
    id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(id),
    action TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Using PostGIS extension for spatial data
ALTER TABLE farms ADD COLUMN geom GEOGRAPHY(Point, 4326);

-- Indexes for performance

CREATE INDEX idx_farm_user ON farms(user_id);
CREATE INDEX idx_weather_date ON weather_data(date);

CREATE TABLE crop_history (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    n_value FLOAT,
    p_value FLOAT,
    k_value FLOAT,
    temperature FLOAT,
    humidity FLOAT,
    ph FLOAT,
    rainfall FLOAT,
    recommended_crop VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
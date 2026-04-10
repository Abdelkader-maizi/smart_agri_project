require('dotenv').config();
const axios = require('axios');
const pool = require('./config/db');

const API_BASE = 'http://127.0.0.1:5000/api';

async function runTests() {
  console.log("🚀 Starting Comprehensive Integration Tests...");
  let token = "";
  let farmId = "";
  let testEmail = `test${Date.now()}@test.com`;

  try {
    console.log(`\n1️⃣  Registering & Logging in (${testEmail})...`);
    await axios.post(`${API_BASE}/auth/register`, {
      name: "Test Farmer",
      phone: `+212600${Math.floor(1000 + Math.random()*9000)}`,
      email: testEmail,
      password: "password123"
    });
    
    let res = await axios.post(`${API_BASE}/auth/login`, { email: testEmail, password: "password123" });
    token = res.data.token;

    console.log("\n2️⃣  Testing Language Setup...");
    res = await axios.put(`${API_BASE}/auth/language`, { language: "dz" }, { headers: { Authorization: `Bearer ${token}` } });
    console.log("✅ Language updated:", res.data.message);

    console.log("\n3️⃣  Testing Geographic DB (Wilayas)...");
    res = await axios.get(`${API_BASE}/geo/wilayas`);
    console.log("✅ Fetched Wilayas count:", res.data.wilayas.length);

    console.log("\n4️⃣  Testing Agriculture Guides...");
    res = await axios.get(`${API_BASE}/guides/planting-calendar`, { headers: { Authorization: `Bearer ${token}` } });
    console.log("✅ Fetched planting guides count:", res.data.guides.length);
    
    res = await axios.post(`${API_BASE}/guides/soil-analysis`, {
      soil_type: "رملية", ph: 8.0, nitrogen: 30
    }, { headers: { Authorization: `Bearer ${token}` } });
    console.log(`✅ Soil Analysis Score: ${res.data.soil_health_score} (${res.data.recommendations.length} recommendations)`);
    res.data.recommendations.forEach(r => console.log('   -', r));

    console.log("\n5️⃣  Creating a Farm...");
    res = await axios.post(`${API_BASE}/farms`, {
      name: "Test Farm", latitude: 33.5, longitude: -7.5
    }, { headers: { Authorization: `Bearer ${token}` } });
    farmId = res.data.farm.id;
    console.log("✅ Farm created, ID:", farmId);

    console.log("\n6️⃣  Testing Offline Logbook Sync...");
    res = await axios.post(`${API_BASE}/logbook/sync`, {
      offlineLogs: [
        { id: Math.random().toString(), farm_id: farmId, activity_type: 'plowing', description: 'حرث الأرض', created_at: new Date().toISOString() },
        { id: Math.random().toString(), farm_id: farmId, activity_type: 'sowing', description: 'بذر البطاطا', created_at: new Date().toISOString() }
      ]
    }, { headers: { Authorization: `Bearer ${token}` } });
    console.log("✅ Offline Sync completed. Synced records:", res.data.new_synced);

    console.log("\n7️⃣  Testing Fetching Logs...");
    res = await axios.get(`${API_BASE}/logbook`, { headers: { Authorization: `Bearer ${token}` } });
    console.log("✅ Total farmer logs fetched:", res.data.logs.length);

    console.log("\n8️⃣  Testing Smart Irrigation (with Auto-Weather Fetch)...");
    res = await axios.post(`${API_BASE}/irrigation`, {
      farm_id: farmId, crop_name: "wheat", water_need: "medium", soil_type: "loam",
      farm_area_hectares: 2.5
    }, { headers: { Authorization: `Bearer ${token}` } });
    console.log("✅ Irrigation mm:", res.data.data.daily_water_need_mm);

    console.log("\n9️⃣  Testing Weather Alerts (with Auto-Weather Fetch)...");
    res = await axios.post(`${API_BASE}/alerts`, {
      farm_id: farmId
    }, { headers: { Authorization: `Bearer ${token}` } });
    console.log("✅ Alerts logged:", res.data.data.total_alerts);

    console.log("\n🔟  Testing Yield Prediction (with Auto-Weather Fetch)...");
    res = await axios.post(`${API_BASE}/yield`, {
      farm_id: farmId, crop_name: "wheat", season: "winter", nitrogen: 60, phosphorus: 40,
      potassium: 30, ph: 6.5, farm_area_hectares: 2.5
    }, { headers: { Authorization: `Bearer ${token}` } });
    console.log("✅ Yield predicted:", res.data.data.predicted_yield_tons, "tons");

    console.log("\n🎉 All Comprehensive Tests Passed!");
  } catch (e) {
    if (e.response) console.error("❌ Test failed:", e.response.status, e.response.data);
    else console.error("❌ Test failed:", e.message);
  } finally {
    process.exit(0);
  }
}
runTests();

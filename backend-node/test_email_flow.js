require('dotenv').config();
const axios = require('axios');
const pool = require('./config/db');

const API_BASE = 'http://127.0.0.1:5000/api';
const testEmail = 'maizi.abdelkader@fs.univ-medea.dz';
const testPhone = '+213' + Math.floor(100000000 + Math.random() * 900000000);

async function runEmailTests() {
  console.log(`🚀 Starting Email Flow Tests for ${testEmail}...`);

  try {
    // 0. Clean up existing user if needed
    await pool.query("DELETE FROM users WHERE email=$1", [testEmail]);
    console.log("🧹 Cleaned up existing user record.");

    // 1. Register -> Should send Welcome Email
    console.log("\n1️⃣ Registering...");
    await axios.post(`${API_BASE}/auth/register`, {
      name: "Abdelkader Maizi",
      phone: testPhone,
      email: testEmail,
      password: "password123",
      language: "ar" // use Arabic this time
    });
    console.log("✅ Registration complete. (Welcome Email Sent)");

    // Wait 2 seconds
    await new Promise(r => setTimeout(r, 2000));

    // 2. Login -> Should send New Login Email
    console.log("\n2️⃣ Logging in...");
    await axios.post(`${API_BASE}/auth/login`, {
      email: testEmail,
      password: "password123"
    });
    console.log("✅ Login complete. (New Login Email Sent)");

    await new Promise(r => setTimeout(r, 2000));

    // 3. Forgot Password -> Should send Token Email
    console.log("\n3️⃣ Requesting Password Reset...");
    await axios.post(`${API_BASE}/auth/forgot-password`, {
      email: testEmail
    });
    console.log("✅ Forgot Password request complete. (Token Email Sent)");

    // Fetch token from DB
    const res = await pool.query("SELECT reset_token FROM users WHERE email=$1", [testEmail]);
    const token = res.rows[0].reset_token;
    console.log(`   (Internal check - token retrieved from DB: ${token})`);

    await new Promise(r => setTimeout(r, 2000));

    // 4. Reset Password -> Should send Reset Success Email
    console.log("\n4️⃣ Resetting Password...");
    await axios.post(`${API_BASE}/auth/reset-password`, {
      email: testEmail,
      token: token,
      new_password: "newpassword123"
    });
    console.log("✅ Password Reset complete. (Success Email Sent)");

    console.log("\n🎉 All 4 Emails should have been successfully delivered to the inbox!");
  } catch (e) {
    if (e.response) console.error("❌ Test failed:", e.response.status, e.response.data);
    else console.error("❌ Test failed:", e.message);
  } finally {
    pool.end();
  }
}
runEmailTests();

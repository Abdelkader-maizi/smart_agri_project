require("dotenv").config(); // must be first

const dns = require('dns');
dns.setDefaultResultOrder('ipv4first'); // Fix IPv6 SMTP ENETUNREACH issues

const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const rateLimit = require("express-rate-limit");
const pool = require("./config/db");

const app = express();

// --- 1. Security headers (helmet) ---
app.use(helmet());

// --- 2. CORS ---
app.use(cors());

// --- 3. Parse JSON ---
app.use(express.json());

// --- 4. Rate limiters ---

// General limiter: all routes → max 100 requests per 15 minutes per IP
const generalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  standardHeaders: true,  // sends RateLimit-* headers to the client
  legacyHeaders: false,
  message: { success: false, error: "Too many requests, please try again later." },
});

// Strict limiter: login/register → max 10 attempts per 15 minutes per IP
// Prevents brute-force attacks on passwords
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, error: "Too many login attempts, please try again in 15 minutes." },
});

app.use(generalLimiter);

// --- 5. Check PostgreSQL connection ---
pool.query("SELECT NOW()", (err) => {
  if (err) console.error("❌ Failed to connect to PostgreSQL:", err.message);
  else console.log("✅ PostgreSQL connected successfully.");
});

// --- 6. Routes ---
app.use("/api/auth", authLimiter, require("./routes/auth"));
app.use("/api/farms", require("./routes/farms"));
app.use("/api/predict", require("./routes/predict"));
app.use("/api/irrigation", require("./routes/irrigation"));
app.use("/api/alerts", require("./routes/alerts"));
app.use("/api/yield", require("./routes/yield"));
app.use("/api/geo", require("./routes/geographic"));
app.use("/api/logbook", require("./routes/logbook"));
app.use("/api/guides", require("./routes/guides"));
app.use("/api/admin", require("./routes/admin"));
app.use("/api/weather", require("./routes/weather"));
app.use("/api/chat", require("./routes/chat"));

// --- 7. Health check ---
app.get("/", (req, res) => {
  res.json({ message: "Smart Farming API is running.", status: "healthy" });
});

// --- 8. Global error handler ---
app.use((err, req, res, next) => {
  console.error("Unhandled error:", err.stack);
  res.status(500).json({ success: false, error: "An unexpected error occurred." });
});

// --- 9. Start server ---
const PORT = process.env.PORT || 5000;
app.listen(PORT, "0.0.0.0", () => {
  console.log(`🚀 Server running on port ${PORT}`);
});
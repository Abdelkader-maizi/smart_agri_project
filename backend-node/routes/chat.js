const express = require('express');
const router = express.Router();
const { GoogleGenerativeAI } = require('@google/generative-ai');

// Initialize Gemini API
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY || "[GCP_API_KEY]");

// Define the Smart Agriculture persona
const SYSTEM_INSTRUCTION = `
You are an expert Smart Agriculture Assistant. 
You help farmers and administrators manage their farms, offering advice on:
- Crop selection based on soil nutrients (N, P, K), pH, and weather.
- Smart irrigation scheduling according to temperature, humidity, and rainfall.
- Yield optimization and fertilizer recommendations.
- Weather alerts (frost, heat, wind, floods).

Keep your responses concise, helpful, and focused on agriculture. If a user asks about non-agricultural topics, gently guide them back to farming or the system's capabilities.
Use a professional yet friendly tone.
`;

router.post('/', async (req, res) => {
  try {
    const { message } = req.body;

    if (!message) {
      return res.status(400).json({ error: 'Message is required' });
    }

    if (!process.env.GEMINI_API_KEY) {
      // Mock response if API key is missing
      return res.json({
        reply: "Hello! I am the Smart Agriculture Assistant. It looks like my AI capabilities are currently disabled (missing GEMINI_API_KEY in .env). Once configured, I can help you with crop advice, weather alerts, and irrigation schedules!"
      });
    }

    // For better experience and stability, we use Gemini Flash Latest
    const model = genAI.getGenerativeModel({ model: 'gemini-flash-latest', systemInstruction: SYSTEM_INSTRUCTION });

    const result = await model.generateContent(message);
    const text = result.response.text();

    res.json({ reply: text });

  } catch (error) {
    console.error('Chatbot error:', error);
    res.status(500).json({ error: 'Failed to generate a response from the AI model.', details: error.message });
  }
});

module.exports = router;

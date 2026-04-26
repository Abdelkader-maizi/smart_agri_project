const { GoogleGenerativeAI } = require('@google/generative-ai');
require('dotenv').config();
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

const SYSTEM_INSTRUCTION = "You are an expert Smart Agriculture Assistant.";

async function run() {
  try {
    const model = genAI.getGenerativeModel({ 
      model: 'gemini-flash-latest',
      systemInstruction: SYSTEM_INSTRUCTION
    });
    const result = await model.generateContent('Hi');
    console.log('success:', result.response.text());
  } catch(e) { 
    console.error('failed:', e); 
  }
}
run();

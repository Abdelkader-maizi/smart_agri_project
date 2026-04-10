const router = require("express").Router();
const auth = require("../middleware/auth");

// 1. Guides for Planting times
router.get("/planting-calendar", auth, (req, res) => {
  const calendar = [
    { crop: "wheat", name_ar: "القمح", recommended_months: ["october", "november", "december"], best_temp: "15-25" },
    { crop: "potato", name_ar: "البطاطا", recommended_months: ["january", "february", "august", "september"], best_temp: "15-20" },
    { crop: "tomato", name_ar: "الطماطم", recommended_months: ["march", "april", "may"], best_temp: "20-27" },
    { crop: "barley", name_ar: "الشعير", recommended_months: ["october", "november"], best_temp: "10-20" }
  ];
  res.json({ success: true, guides: calendar });
});

// 2. Fertilizers & Pesticides Manual
router.get("/fertilizers", auth, (req, res) => {
  const manuals = [
    { item: "Urea 46%", type: "Fertilizer", rule_ar: "استخدم للقمح بمعدل 150 كغ/هكتار. يوزع بالتساوي وقت الإيقاظ." },
    { item: "NPK 15-15-15", type: "Fertilizer", rule_ar: "مناسب جداً للتربة الضعيفة وخاصة للبطاطا والطماطم قبل الغرس بأسبوع." },
    { item: "Copper Sulfate", type: "Pesticide", rule_ar: "يستخدم كمبيد فطري للكروم والطماطم لمنع مرض الميلديو. 20 جرام لكل 10 لتر ماء." }
  ];
  res.json({ success: true, manuals });
});

// 3. Simple Soil Analysis Logic (Simulating an expert rule-based system)
router.post("/soil-analysis", auth, (req, res) => {
  const { soil_type, ph, nitrogen, phosphorus, potassium } = req.body;
  
  if (!soil_type || ph === undefined) {
    return res.status(400).json({ success: false, error: "Soil type and pH are required" });
  }

  let recommendations = [];

  if (ph < 6.0) {
    recommendations.push("التربة حامضية جداً: ينصح بإضافة الجير الزراعي (Lime) لرفع نسبة الحموضة.");
  } else if (ph > 7.5) {
    recommendations.push("التربة قاعدية جداً: أضف سماد كبريتي زراعي وتقليل استخدام المياه القلوية.");
  }

  if (soil_type.toLowerCase() === "sandy" || soil_type === "رملية") {
    recommendations.push("تربة رملية: تفقد المياه والمغذيات بسرعة. استخدم الأسمدة العضوية لتحسين قدرتها على الاحتفاظ بالماء.");
  } else if (soil_type.toLowerCase() === "clay" || soil_type === "طينية") {
    recommendations.push("تربة طينية: ثقيلة وتحتفظ بالماء. تجنب الإفراط في الري لمنع تعفن الجذور، وتأكد من الحرث العميق للتهوية.");
  }

  if (nitrogen !== undefined && nitrogen < 40) {
    recommendations.push("نقص النيتروجين المكتشف يحد من نمو الأوراق. أضف أسمدة أزوتية (مثل اليوريا).");
  }

  if (recommendations.length === 0) {
    recommendations.push("حالة التربة لديك ممتازة ومثالية لأغلب المزروعات.");
  }

  res.json({ 
    success: true, 
    soil_health_score: recommendations.length > 1 ? "Poor" : "Good",
    recommendations 
  });
});

module.exports = router;

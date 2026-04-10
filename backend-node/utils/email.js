const nodemailer = require("nodemailer");

// --- Nodemailer Transporter Setup ---
let transporter;
(async () => {
  const user = process.env.SMTP_USER;
  const pass = process.env.SMTP_PASS;
  
  if (!user || !pass) {
    try {
      const testAccount = await nodemailer.createTestAccount();
      transporter = nodemailer.createTransport({
        host: "smtp.ethereal.email",
        port: 587,
        secure: false, 
        auth: {
          user: testAccount.user, 
          pass: testAccount.pass, 
        },
      });
      console.log(`✉️  Nodemailer initialized with test account: ${testAccount.user}`);
    } catch(err) {
      console.error("Failed to initialize test email account", err);
    }
  } else {
    transporter = nodemailer.createTransport({
      host: process.env.SMTP_HOST || "smtp.gmail.com",
      port: process.env.SMTP_PORT || 587,
      auth: { user, pass },
    });
  }
})();

// --- Email Template Helper ---
function generateEmailHTML(lang, title, contentHTML) {
  const isEn = lang === 'en';
  const systemName = isEn ? "Smart Agriculture Advisor" : "المستشار الزراعي الذكي";
  const copyright = isEn ? `© ${new Date().getFullYear()} Smart Agriculture System. All rights reserved.` : `© ${new Date().getFullYear()} مشروع الزراعة الذكية. جميع الحقوق محفوظة.`;
  
  return `
<!DOCTYPE html>
<html lang="${isEn ? 'en' : 'ar'}" dir="${isEn ? 'ltr' : 'rtl'}">
<head>
    <meta charset="UTF-8">
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }
        .container { max-width: 600px; margin: 40px auto; background-color: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 15px rgba(0,0,0,0.05); border: 1px solid #eaefe9; }
        .header { background-color: #2d5a27; color: #ffffff; padding: 30px 20px; text-align: center; }
        .header h1 { margin: 0; font-size: 26px; font-weight: 700; letter-spacing: 0.5px; }
        .content { padding: 40px 30px; text-align: center; color: #333333; }
        .content p { font-size: 16px; line-height: 1.6; margin-bottom: 25px; color: #555555; }
        .token-box { background-color: #f0f7f1; border: 2px dashed #408237; border-radius: 8px; padding: 20px 40px; margin: 30px auto; display: inline-block; }
        .token { font-size: 38px; font-weight: bold; color: #2d5a27; letter-spacing: 12px; margin: 0; }
        .footer { background-color: #f9fbf9; padding: 20px; text-align: center; font-size: 13px; color: #999999; border-top: 1px solid #eeeeee; }
        .warning { font-size: 14px; color: #d35400; margin-top: 25px; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>${systemName}</h1>
        </div>
        <div class="content">
            <h2 style="color: #2d5a27; margin-top:0; font-size: 22px;">${title}</h2>
            ${contentHTML}
        </div>
        <div class="footer">
            <p>${copyright}</p>
        </div>
    </div>
</body>
</html>`;
}

// Global generic sender
async function sendSystemEmail(to, subject, htmlContent) {
  if (!transporter) {
    console.error("Transporter is not fully initialized yet.");
    return false;
  }
  try {
    const mailOptions = {
      from: `"Smart Agriculture" <${process.env.SMTP_USER || "noreply@smartagriculture.com"}>`,
      to,
      subject,
      html: htmlContent,
    };
    const info = await transporter.sendMail(mailOptions);
    console.log("📨 Email sent:", info.messageId);
    if (nodemailer.getTestMessageUrl(info)) {
      console.log("Preview URL:", nodemailer.getTestMessageUrl(info));
    }
    return true;
  } catch (error) {
    console.error("System Email error:", error.message);
    return false;
  }
}

// Specialized Alert Sender
async function sendAlertEmail(email, lang, alertData) {
  const isEn = lang === 'en';
  
  const title = isEn ? "🚨 Weather Alert for Your Farm" : "🚨 إنذار مناخي لمزرعتك";
  const subject = isEn ? `Smart Agriculture Alert: ${alertData.type}` : `إنذار الزراعة الذكية: ${alertData.type}`;
  
  let typeLabel = alertData.type;
  let severityLabel = alertData.severity || "";
  let messageLabel = alertData.message || "";
  
  // Basic Translation Mapping for Common Types
  if (!isEn) {
    const tLower = typeLabel.toLowerCase();
    if (tLower.includes("frost")) typeLabel = "صقيع محتمل";
    else if (tLower.includes("heat")) typeLabel = "موجة حر شديدة";
    else if (tLower.includes("wind")) typeLabel = "رياح عاتية";
    else if (tLower.includes("drought")) typeLabel = "تنبيه جفاف";
    else if (tLower.includes("flood")) typeLabel = "فيضان محتمل";

    const sLower = severityLabel.toLowerCase();
    if (sLower === "critical") severityLabel = "حرج (خطورة عالية)";
    else if (sLower === "warning") severityLabel = "تحذير (خطورة متوسطة)";
    else if (sLower === "info") severityLabel = "ملاحظة (خطورة منخفضة)";

    // Translate dynamic messages coming from AI service
    messageLabel = messageLabel
      .replace(/Frost risk detected/g, "تم اكتشاف خطر الصقيع")
      .replace(/Temperature is ([\-\d\.]+)°C/g, "درجة الحرارة هي $1 درجة مئوية")
      .replace(/Protect sensitive crops immediately — cover plants or activate frost protection irrigation to create an insulating ice layer\./g, "قم بحماية المحاصيل الحساسة فوراً — قم بتغطية النباتات أو تشغيل الري الواقي من الصقيع لتكوين طبقة جليد عازلة.")
      .replace(/Extreme heat alert/g, "إنذار من حرارة شديدة")
      .replace(/Increase irrigation frequency, apply mulch to retain soil moisture, and consider shading for heat-sensitive crops\./g, "قم بزيادة وتيرة الري، واستخدم النشارة للاحتفاظ برطوبة التربة، وفكر في تظليل المحاصيل الحساسة للحرارة.")
      .replace(/High temperature warning/g, "تحذير من ارتفاع درجة الحرارة")
      .replace(/Monitor crops for heat stress and ensure adequate soil moisture\./g, "راقب المحاصيل بحثاً عن الإجهاد الحراري وتأكد من توفر رطوبة كافية في التربة.")
      .replace(/Strong wind alert/g, "إنذار من رياح قوية")
      .replace(/Wind speed is ([\d\.]+) km\/h/g, "سرعة الرياح هي $1 كم/ساعة")
      .replace(/Secure greenhouse structures, support tall crops with stakes, and avoid spraying pesticides or fertilizers until winds subside\./g, "ثبّت هياكل البيوت المحمية، وادعم المحاصيل الطويلة بالأوتاد، وتجنب رش المبيدات أو الأسمدة حتى تهدأ الرياح.")
      .replace(/Moderate wind advisory/g, "تحذير من رياح معتدلة")
      .replace(/Check young plants and trellised crops for wind damage\./g, "افحص النباتات الصغيرة والمحاصيل المتسلقة بحثاً عن أضرار الرياح.")
      .replace(/Heavy rainfall detected: ([\d\.]+) mm/g, "تم اكتشاف هطول أمطار غزيرة: $1 ملم")
      .replace(/Check drainage systems, watch for waterlogging in low-lying fields, and delay any soil-disturbing operations\./g, "تحقق من أنظمة الصرف، وانتبه لتجمع المياه في الحقول المنخفضة، وأجّل أي عمليات تقليب للتربة.")
      .replace(/Drought stress conditions: no rainfall, ([\d\.]+)°C, ([\d\.]+)% humidity/g, "ظروف إجهاد جفاف: لا يوجد هطول أمطار، الحرارة $1 درجة مئوية، الرطوبة $2%")
      .replace(/Activate irrigation immediately and apply mulch to conserve soil moisture\./g, "قم بتشغيل الري فوراً واستخدم النشارة للحفاظ على رطوبة التربة.");
  }

  const contentHTML = isEn ? `
    <p>A climate warning has been triggered for your agricultural property.</p>
    <div style="background-color: #fff3cd; border: 1px solid #ffeeba; border-radius: 8px; padding: 15px; margin: 20px 0; text-align: left;">
      <h3 style="color: #856404; margin-top: 0;">Alert: ${typeLabel}</h3>
      <p style="color: #856404; margin-bottom: 0;"><strong>Severity:</strong> ${alertData.severity}</p>
      <p style="color: #856404; margin-bottom: 0;"><strong>Details:</strong> ${alertData.message}</p>
    </div>
    <p>Please take necessary precautions to protect your crops.</p>
  ` : `
    <p>تم إطلاق تحذير مناخي يخص الأراضي الزراعية التابعة لك.</p>
    <div style="background-color: #fff3cd; border: 1px solid #ffeeba; border-radius: 8px; padding: 15px; margin: 20px 0; text-align: right;" dir="rtl">
      <h3 style="color: #856404; margin-top: 0;">نوع الإنذار: ${typeLabel}</h3>
      <p style="color: #856404; margin-bottom: 0;"><strong>مستوى الخطورة:</strong> ${severityLabel}</p>
      <p style="color: #856404; margin-bottom: 0;"><strong>التفاصيل:</strong> ${messageLabel}</p>
    </div>
    <p>يُرجى اتخاذ التدابير اللازمة لحماية المحاصيل الزراعية فوراً.</p>
  `;

  const finalHtml = generateEmailHTML(lang, title, contentHTML);
  return await sendSystemEmail(email, subject, finalHtml);
}

module.exports = {
  transporter,
  generateEmailHTML,
  sendSystemEmail,
  sendAlertEmail
};

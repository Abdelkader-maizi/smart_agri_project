require('dotenv').config();
const nodemailer = require('nodemailer');

async function testEmail() {
    const user = process.env.SMTP_USER;
    const pass = process.env.SMTP_PASS;
    const targetEmail = "maizi.abdelkader@fs.univ-medea.dz";
    const token = "192305"; // Simulated English token

    const transporter = nodemailer.createTransport({
      host: process.env.SMTP_HOST || "smtp.gmail.com",
      port: process.env.SMTP_PORT || 587,
      auth: { user, pass },
    });

    const emailHTML_EN = `
<!DOCTYPE html>
<html lang="en">
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
            <h1>Smart Agriculture Advisor</h1>
        </div>
        <div class="content">
            <h2 style="color: #2d5a27; margin-top:0; font-size: 22px;">Password Reset Request</h2>
            <p>Welcome,<br>We received a request to reset your password. Please use the secret code below to complete the process within the app:</p>
            <div class="token-box">
                <p class="token">${token}</p>
            </div>
            <p class="warning">⚠️ This code is only valid for 15 minutes for your security.</p>
            <p style="font-size: 14px; margin-top: 35px; color: #888;">If you did not request this code, please ignore this email.</p>
        </div>
        <div class="footer">
            <p>© ${new Date().getFullYear()} Smart Agriculture System. All rights reserved.</p>
        </div>
    </div>
</body>
</html>`;

    try {
        console.log(`Sending ENGLISH styled email template to ${targetEmail}...`);
        const info = await transporter.sendMail({
            from: '"Smart Agriculture Advisor" <' + user + '>',
            to: targetEmail,
            subject: "Account Recovery - Password Reset Code 🔐",
            html: emailHTML_EN
        });
        console.log("✅ English Template Email sent! Message ID:", info.messageId);
    } catch(e) {
         console.error("❌ Failed to send email:", e.message);
    }
}
testEmail();

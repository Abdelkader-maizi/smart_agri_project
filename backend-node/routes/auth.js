const router = require("express").Router();
const pool = require("../config/db");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const auth = require("../middleware/auth");
const { transporter, generateEmailHTML } = require("../utils/email");


// === Register ===
router.post("/register", async (req, res) => {
  try {
    const { name, phone, email, password } = req.body;

    // Input validation
    if (!name || !phone || !email || !password)
      return res.status(400).json({ success: false, error: "Name, phone, email, and password are required" });

    const phoneRegex = /^\+?[0-9]{10,15}$/;
    if (!phoneRegex.test(phone))
      return res.status(400).json({ success: false, error: "Invalid phone number format" });

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email))
      return res.status(400).json({ success: false, error: "Invalid email format" });

    if (password.length < 6)
      return res.status(400).json({ success: false, error: "Password must be at least 6 characters" });

    // Check if phone or email already registered
    const existing = await pool.query("SELECT id FROM users WHERE phone=$1 OR email=$2", [phone, email]);
    if (existing.rows.length > 0)
      return res.status(409).json({ success: false, error: "Phone number or email already registered" });

    const hashed = await bcrypt.hash(password, 10);

    const user = await pool.query(
      "INSERT INTO users(name, phone, email, password) VALUES($1,$2,$3,$4) RETURNING id, name, phone, email",
      [name, phone, email, hashed]
    );

    // Send Welcome Email
    if (transporter && email) {
      const isEn = (req.body.language || 'ar') === 'en';
      const title = isEn ? "Welcome to Smart Agriculture!" : "مرحباً بك في الزراعة الذكية!";
      const subject = isEn ? "Welcome to Smart Agriculture Advisor 🌾" : "مرحباً بك في المستشار الزراعي الذكي 🌾";
      const HTML = isEn ? 
        `<p>Hello <b>${name}</b>,</p><p>Your account has been successfully created. We are excited to help you manage your farm.</p>` :
        `<p>مرحباً <b>${name}</b>،</p><p>تم إنشاء حسابك بنجاح. نحن متحمسون لمساعدتك في إدارة مزرعتك بكفاءة.</p>`;
      
      transporter.sendMail({
        from: '"' + (isEn ? "Smart Agriculture Advisor" : "المستشار الزراعي الذكي") + '" <' + (process.env.SMTP_USER || 'noreply@smartagri.com') + '>',
        to: email,
        subject: subject,
        html: generateEmailHTML(isEn ? 'en' : 'ar', title, HTML),
      }).catch(err => console.error("Register email error:", err.message));
    }

    res.status(201).json({ success: true, user: user.rows[0] });

  } catch (err) {
    console.error("Register error:", err.message);
    res.status(500).json({ success: false, error: "Server error during registration" });
  }
});

// === Login ===
router.post("/login", async (req, res) => {
  try {
    // allow phone OR email
    const { phone, email, password } = req.body;
    const identifier = phone || email;

    // Input validation
    if (!identifier || !password)
      return res.status(400).json({ success: false, error: "Phone/Email and password are required" });

    let user;
    if (email) {
      user = await pool.query("SELECT * FROM users WHERE email=$1", [email]);
    } else {
      user = await pool.query("SELECT * FROM users WHERE phone=$1", [phone]);
    }

    if (user.rows.length === 0)
      return res.status(400).json({ success: false, error: "User not found" });

    const valid = await bcrypt.compare(password, user.rows[0].password);

    if (!valid)
      return res.status(400).json({ success: false, error: "Wrong password" });

    const token = jwt.sign(
      { id: user.rows[0].id },
      process.env.JWT_SECRET,
      { expiresIn: "7d" }
    );

    // Send Login Notification Email
    if (transporter && user.rows[0].email) {
      const u = user.rows[0];
      const lang = u.language || 'ar';
      const isEn = lang === 'en';
      const time = new Date().toLocaleString(isEn ? 'en-US' : 'ar-EG');
      const title = isEn ? "New Login Notification" : "إشعار تسجيل دخول جديد";
      const subject = isEn ? "New Login Detected 🛡️" : "تسجيل دخول جديد لحسابك 🛡️";
      
      const HTML = isEn ? 
        `<p>Welcome back, <b>${u.name}</b>!</p><p>We noticed a new login to your account on <b>${time}</b>.</p><p>If this was you, you can safely ignore this email. If you did not authorize this login, please reset your password immediately.</p>` :
        `<p>مرحباً <b>${u.name}</b>، أهلاً بك مجدداً!</p><p>لقد تم تسجيل الدخول إلى حسابك في <b>${time}</b>.</p><p>إذا كان هذا أنت، يمكنك تجاهل هذا البريد. إذا لم تقم بتسجيل الدخول، يرجى تغيير كلمة المرور الخاصة بك على الفور.</p>`;

      transporter.sendMail({
        from: '"' + (isEn ? "Smart Agriculture Advisor" : "المستشار الزراعي الذكي") + '" <' + (process.env.SMTP_USER || 'noreply@smartagri.com') + '>',
        to: u.email,
        subject: subject,
        html: generateEmailHTML(lang, title, HTML),
      }).catch(err => console.error("Login email error:", err.message));
    }

    res.json({
      success: true,
      token,
      user: {
        id: user.rows[0].id,
        name: user.rows[0].name,
        phone: user.rows[0].phone,
        email: user.rows[0].email,
      }
    });

  } catch (err) {
    console.error("Login error:", err.message);
    res.status(500).json({ success: false, error: "Server error during login" });
  }
});

// === Forgot Password ===
router.post("/forgot-password", async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) return res.status(400).json({ success: false, error: "Email is required" });

    const user = await pool.query("SELECT id, language FROM users WHERE email=$1", [email]);
    if (user.rows.length === 0) {
      // Don't leak that the email doesn't exist for security
      return res.status(200).json({ success: true, message: "If your email is registered, a reset code was sent" });
    }

    const lang = user.rows[0].language || 'ar';

    // Generate 6-digit token
    const token = Math.floor(100000 + Math.random() * 900000).toString();
    const expires = new Date(Date.now() + 15 * 60 * 1000); // 15 minutes

    await pool.query(
      "UPDATE users SET reset_token=$1, reset_token_expires=$2 WHERE email=$3",
      [token, expires, email]
    );

    // Send email
    if (transporter) {
      const isEn = lang === 'en';
      let subject = isEn ? "Account Recovery - Password Reset Code 🔐" : "استرداد الحساب - رمز إعادة تعيين كلمة المرور 🔐";
      let senderName = isEn ? "Smart Agriculture Advisor" : "المستشار الزراعي الذكي";
      let title = isEn ? "Password Reset Request" : "إعادة تعيين كلمة المرور";
      
      let HTML = isEn ? 
        `<p>Welcome,<br>We received a request to reset your password. Please use the secret code below to complete the process within the app:</p>
         <div class="token-box" style="background-color: #f0f7f1; border: 2px dashed #408237; border-radius: 8px; padding: 20px 40px; margin: 30px auto; display: inline-block;">
            <p class="token" style="font-size: 38px; font-weight: bold; color: #2d5a27; letter-spacing: 12px; margin: 0;">${token}</p>
         </div>
         <p class="warning" style="font-size: 14px; color: #d35400; margin-top: 25px; font-weight: bold;">⚠️ This code is only valid for 15 minutes for your security.</p>
         <p style="font-size: 14px; margin-top: 35px; color: #888;">If you did not request this code, please ignore this email.</p>` :
        `<p>مرحباً بك،<br>لقد تلقينا طلباً لإعادة تعيين كلمة المرور الخاصة بحسابك. يرجى استخدام الرمز السري أدناه لإكمال العملية من داخل التطبيق:</p>
         <div class="token-box" style="background-color: #f0f7f1; border: 2px dashed #408237; border-radius: 8px; padding: 20px 40px; margin: 30px auto; display: inline-block;">
            <p class="token" style="font-size: 38px; font-weight: bold; color: #2d5a27; letter-spacing: 12px; margin: 0;">${token}</p>
         </div>
         <p class="warning" style="font-size: 14px; color: #d35400; margin-top: 25px; font-weight: bold;">⚠️ هذا الرمز صالح لمدة 15 دقيقة فقط حرصاً على أمانك.</p>
         <p style="font-size: 14px; margin-top: 35px; color: #888;">إذا لم تقم بطلب هذا الرمز، يُرجى تجاهل هذا البريد ولن يطرأ أي تغيير على حسابك.</p>`;

      const info = await transporter.sendMail({
        from: '"' + senderName + '" <' + (process.env.SMTP_USER || 'noreply@smartagri.com') + '>',
        to: email,
        subject: subject,
        html: generateEmailHTML(lang, title, HTML),
      });
      console.log(`[DEV] Password reset email sent. Message ID: ${info.messageId}`);
    }

    res.json({ success: true, message: "Password reset code sent to email" });

  } catch (err) {
    console.error("Forgot pass error:", err.message);
    res.status(500).json({ success: false, error: "Server error while sending reset email" });
  }
});

// === Reset Password ===
router.post("/reset-password", async (req, res) => {
  try {
    const { email, token, new_password } = req.body;
    if (!email || !token || !new_password) {
      return res.status(400).json({ success: false, error: "Email, token, and new_password are required" });
    }

    if (new_password.length < 6) {
      return res.status(400).json({ success: false, error: "Password must be at least 6 characters" });
    }

    const result = await pool.query(
      "SELECT id, name, language, reset_token_expires FROM users WHERE email=$1 AND reset_token=$2",
      [email, token]
    );

    if (result.rows.length === 0) {
      return res.status(400).json({ success: false, error: "Invalid or incorrect reset token" });
    }

    if (new Date() > new Date(result.rows[0].reset_token_expires)) {
      return res.status(400).json({ success: false, error: "Reset token has expired" });
    }

    const hashed = await bcrypt.hash(new_password, 10);

    await pool.query(
      "UPDATE users SET password=$1, reset_token=NULL, reset_token_expires=NULL WHERE email=$2",
      [hashed, email]
    );

    // Send Success Email
    if (transporter && email) {
      const u = result.rows[0];
      const lang = u.language || 'ar';
      const isEn = lang === 'en';
      const title = isEn ? "Password Changed" : "تغيير كلمة المرور";
      const subject = isEn ? "Password Reset Successful ✅" : "تم تغيير كلمة المرور بنجاح ✅";
      
      const HTML = isEn ? 
        `<p>Hello <b>${u.name}</b>,</p><p>Your password has been successfully reset.</p><p>If you did not make this change, please contact support immediately.</p>` :
        `<p>مرحباً <b>${u.name}</b>،</p><p>تم إعادة تعيين كلمة المرور الخاصة بحسابك بنجاح.</p><p>إذا لم تقم بطلب هذا التغيير، يرجى التواصل مع الدعم الفني فوراً.</p>`;

      transporter.sendMail({
        from: '"' + (isEn ? "Smart Agriculture Advisor" : "المستشار الزراعي الذكي") + '" <' + (process.env.SMTP_USER || 'noreply@smartagri.com') + '>',
        to: email,
        subject: subject,
        html: generateEmailHTML(lang, title, HTML),
      }).catch(err => console.error("Reset success email error:", err.message));
    }

    res.json({ success: true, message: "Password has been successfully reset" });

  } catch (err) {
    console.error("Reset pass error:", err.message);
    res.status(500).json({ success: false, error: "Server error during password reset" });
  }
});

// === Update Language ===
router.put("/language", auth, async (req, res) => {
  try {
    const { language } = req.body;
    if (!['ar', 'amz', 'dz'].includes(language)) {
      return res.status(400).json({ success: false, error: "Unsupported language. Use ar, amz, or dz" });
    }
    
    await pool.query("UPDATE users SET language=$1 WHERE id=$2", [language, req.user.id]);
    res.json({ success: true, message: `Language updated to ${language}` });
  } catch (err) {
    console.error("Language update error:", err.message);
    res.status(500).json({ success: false, error: "Server error" });
  }
});

module.exports = router;
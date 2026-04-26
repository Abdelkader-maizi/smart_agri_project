import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Ensure import paths are correct
import 'screens/auth/welcome_page.dart'; 
import 'screens/auth/login_page.dart';
import 'screens/auth/signup_page.dart';
import 'screens/home/main_page.dart';

import 'services/api_service.dart';
import 'blocs/auth/auth_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  
  final String? token = prefs.getString('jwt_token');
  final String savedLang = prefs.getString('language') ?? 'ar';
  final bool savedDarkMode = prefs.getBool('is_dark_mode') ?? false;

  final apiService = ApiService();
  
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(apiService),
        ),
      ],
      child: SmartFarmApp(
        initialToken: token,
        initialLang: savedLang,
        initialDarkMode: savedDarkMode,
      ),
    ),
  );
}

class SmartFarmApp extends StatefulWidget {
  final String? initialToken;
  final String initialLang;
  final bool initialDarkMode;

  const SmartFarmApp({
    super.key, 
    this.initialToken,
    required this.initialLang,
    required this.initialDarkMode,
  });

  @override
  State<SmartFarmApp> createState() => _SmartFarmAppState();
}

class _SmartFarmAppState extends State<SmartFarmApp> {
  late String _currentLang;
  late bool _isAppDarkMode;

  @override
  void initState() {
    super.initState();
    _currentLang = widget.initialLang;
    _isAppDarkMode = widget.initialDarkMode;
  }

  void _toggleTheme(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', val);
    setState(() {
      _isAppDarkMode = val;
    });
  }

  // Complete dictionary with all required languages and keys
  final Map<String, Map<String, String>> _translations = {
    'ar': {
      'welcome': 'مرحباً بك في المزرعة الذكية',
      'signup': 'إنشاء حساب جديد',
      'login': 'تسجيل الدخول',
      'name': 'اسم المستخدم',
      'email': 'البريد الإلكتروني',
      'pass': 'كلمة المرور',
      'profile': 'الملف الشخصي',
      'logout': 'خروج',
      'name_error': 'يجب ألا يبدأ الاسم برقم',
      'email_error': 'بريد إلكتروني غير صحيح',
      'pass_error': 'كلمة مرور ضعيفة (8-22 حرف)',
      'start_farming': 'بدأ الزراعة',
      'farming_settings': 'إعدادات الزراعة',
      'weather_data': 'بيانات الطقس',
      'irrigation_schedule': 'برنامج السقي',
      'fertilizer_guide': 'دليل الأسمدة',
      'farming_log': 'سجل الزراعة',
      'harvest_prediction': 'توقع الحصاد',
      'select_region': 'اختيار المنطقة',
      'select_crop': 'اختيار نوع المحصول',
      'menu': 'الرئيسية',
      'settings': 'الإعدادات',
      'change_language': 'تغيير اللغة',
      'dark_mode': 'الوضع المظلم',
      'light_mode': 'الوضع المضيء',
      'exit_confirm': 'تأكيد الخروج',
      'exit_msg': 'هل أنت متأكد أنك تريد الخروج من التطبيق حقاً؟',
      'cancel': 'إلغاء',
      'exit': 'خروج',
      'quick_tools': 'أدوات سريعة',
      'algeria_map': 'خارطة الجزائر',
      'chat': 'المحادثة',
      'ai_assistant': 'المساعد الذكي',
      'predict_yield': 'توقع المحصول',
      'refresh_data': 'تحديث البيانات',
      'retry_gps': 'إعادة المحاولة عبر GPS',
      'select_farm': 'اختر المزرعة',
      'add_new_log': 'إضافة سجل جديد',
      'recent_logs': 'السجلات الأخيرة',
      'save_log': 'حفظ السجل',
      'activity_type': 'نوع النشاط (مثال: ري, زراعة)',
      'description': 'الوصف',
      'add_new_farm': 'إضافة مزرعة جديدة',
      'save_farm': 'حفظ المزرعة',
      'your_farms': 'مزارعك',
      'farm_name': 'اسم المزرعة',
    },
    'en': {
      'welcome': 'Welcome to Smart Farm',
      'signup': 'Create New Account',
      'login': 'Login',
      'name': 'Username',
      'email': 'Email Address',
      'pass': 'Password',
      'profile': 'Profile',
      'logout': 'Logout',
      'name_error': 'Invalid name',
      'email_error': 'Invalid email',
      'pass_error': 'Weak password',
      'start_farming': 'Start Farming',
      'farming_settings': 'Farming Settings',
      'weather_data': 'Weather Data',
      'irrigation_schedule': 'Irrigation Schedule',
      'fertilizer_guide': 'Fertilizer Guide',
      'farming_log': 'Farming Log',
      'harvest_prediction': 'Harvest Prediction',
      'select_region': 'Select Region',
      'select_crop': 'Select Crop',
      'menu': 'Home',
      'settings': 'Settings',
      'change_language': 'Change Language',
      'dark_mode': 'Dark Mode',
      'light_mode': 'Light Mode',
      'exit_confirm': 'Exit Confirmation',
      'exit_msg': 'Are you sure you want to exit the app?',
      'cancel': 'Cancel',
      'exit': 'Exit',
      'quick_tools': 'Quick Tools',
      'algeria_map': 'Algeria Map',
      'chat': 'Chat',
      'ai_assistant': 'AI Assistant',
      'predict_yield': 'Predict Yield',
      'refresh_data': 'Refresh Data',
      'retry_gps': 'Retry via GPS',
      'select_farm': 'Select Farm',
      'add_new_log': 'Add New Log',
      'recent_logs': 'Recent Logs',
      'save_log': 'Save Log',
      'activity_type': 'Activity Type (e.g. Irrigation, Planting)',
      'description': 'Description',
      'add_new_farm': 'Add New Farm',
      'save_farm': 'Save Farm',
      'your_farms': 'Your Farms',
      'farm_name': 'Farm Name',
    },
    'fr': {
      'welcome': 'Bienvenue à Smart Farm',
      'signup': 'Créer un compte',
      'login': 'Connexion',
      'name': 'Nom d\'utilisateur',
      'email': 'E-mail',
      'pass': 'Mot de passe',
      'profile': 'Profil',
      'logout': 'Déconnexion',
      'name_error': 'Nom invalide',
      'email_error': 'E-mail invalide',
      'pass_error': 'Mot de passe faible',
      'start_farming': 'Démarrer l\'agriculture',
      'farming_settings': 'Paramètres agricoles',
      'weather_data': 'Données météo',
      'irrigation_schedule': 'Programme d\'irrigation',
      'fertilizer_guide': 'Guide des engrais',
      'farming_log': 'Journal agricole',
      'harvest_prediction': 'Prédiction de récolte',
      'select_region': 'Choisir la région',
      'select_crop': 'Choisir la culture',
      'menu': 'Accueil',
      'settings': 'Paramètres',
      'change_language': 'Changer la langue',
      'dark_mode': 'Mode sombre',
      'light_mode': 'Mode clair',
      'exit_confirm': 'Confirmation de sortie',
      'exit_msg': 'Êtes-vous sûr de vouloir quitter l\'application ?',
      'cancel': 'Annuler',
      'exit': 'Quitter',
      'quick_tools': 'Outils Rapides',
      'algeria_map': 'Carte d\'Algérie',
      'chat': 'Discussion',
      'ai_assistant': 'Assistant IA',
      'predict_yield': 'Prédire le Rendement',
      'refresh_data': 'Actualiser les Données',
      'retry_gps': 'Réessayer via GPS',
      'select_farm': 'Sélectionner la Ferme',
      'add_new_log': 'Ajouter un Journal',
      'recent_logs': 'Journaux Récents',
      'save_log': 'Enregistrer',
      'activity_type': 'Type d\'Activité',
      'description': 'Description',
      'add_new_farm': 'Ajouter une Ferme',
      'save_farm': 'Enregistrer la Ferme',
      'your_farms': 'Vos Fermes',
      'farm_name': 'Nom de la Ferme',
    }
  };

  // Update language function to handle input from the UI
  void _updateLang(String langName) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (langName == "العربية" || langName == "ar") {
        _currentLang = 'ar';
      } else if (langName == "English" || langName == "en") {
        _currentLang = 'en';
      } else if (langName == "Français" || langName == "fr") {
        _currentLang = 'fr';
      }
    });
    await prefs.setString('language', _currentLang);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Farm',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2ECC71), // Vibrant Green
          brightness: Brightness.light,
          background: const Color(0xFFF4F7F4),
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.black87),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.grey.shade200,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2ECC71),
          brightness: Brightness.dark,
          background: const Color(0xFF0D110D), // Premium Dark
          surface: const Color(0xFF151A15),
        ),
        scaffoldBackgroundColor: const Color(0xFF0D110D),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
      themeMode: _isAppDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: widget.initialToken != null 
          ? MainPage(
              trans: _translations[_currentLang]!, 
              onLangChange: _updateLang,
              isDarkMode: _isAppDarkMode, 
              onThemeChange: _toggleTheme, 
            )
          : WelcomePage(
              trans: _translations[_currentLang]!, 
              onLangChange: _updateLang,
              isDarkMode: _isAppDarkMode, 
              onThemeChange: _toggleTheme, 
            ),
    );
  }
}
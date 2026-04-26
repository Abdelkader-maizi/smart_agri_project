import 'package:flutter/material.dart';
import '../../services/api_service.dart';

import 'views/dashboard_view.dart';
import 'views/farm_manager_view.dart';
import 'views/weather_view.dart';
import 'views/irrigation_view.dart';
import 'views/guides_view.dart';
import 'views/logbook_view.dart';
import 'views/predict_view.dart';
import 'views/chat_view.dart';

class MainPage extends StatefulWidget {
  final Map<String, String> trans;
  final Function(String) onLangChange;
  final bool isDarkMode;
  final Function(bool) onThemeChange;

  const MainPage({
    super.key,
    required this.trans,
    required this.onLangChange,
    required this.isDarkMode,
    required this.onThemeChange,
  });

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ApiService _apiService = ApiService();

  int _currentIndex = 0;
  int _innerMode = 0;
  // Navigation Bar Indices:
  // 0: Home (Dashboard / Sub-pages)
  // 1: Farms (Farm Manager)
  // 2: Chat (AI Assistant)
  // 3: AI Predict
  // 4: Logbook

  // Sub-pages inside Home tab:
  // 0: Dashboard
  // 2: Weather View
  // 3: Irrigation View
  // 4: Guides View

  void _onModeChange(int mode) {
    setState(() {
      if (mode == 1) {
        _currentIndex = 1;
        _innerMode = 0;
      } else if (mode == 5) {
        _currentIndex = 4;
        _innerMode = 0;
      } else if (mode == 6) {
        _currentIndex = 3;
        _innerMode = 0;
      } else {
        _currentIndex = 0;
        _innerMode = mode;
      }
    });
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _currentIndex = index;
      _innerMode = 0; // Reset inner mode when changing tabs
    });
  }

  Future<bool> _onWillPop() async {
    if (_currentIndex != 0 || _innerMode != 0) {
      setState(() {
        _currentIndex = 0;
        _innerMode = 0;
      });
      return false; 
    }

    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(widget.trans['exit_confirm'] ?? "Exit Confirmation", style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black)),
        content: Text(widget.trans['exit_msg'] ?? "Are you sure you want to exit?", style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(widget.trans['cancel'] ?? "Cancel", style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(widget.trans['exit'] ?? "Exit", style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;
  }

  Widget _buildHeader() {
    final String title = widget.trans['welcome'] ?? "Welcome to Smart Farm";
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87, fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const SizedBox(height: 5),
          Text(
            "Manage your crops actively & smartly.",
            style: TextStyle(color: widget.isDarkMode ? Colors.greenAccent.withOpacity(0.8) : Colors.green[700], fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPageContent() {
    if (_currentIndex == 1) {
      return FarmManagerView(key: const ValueKey('farm_manager'), trans: widget.trans, isDarkMode: widget.isDarkMode, apiService: _apiService);
    } else if (_currentIndex == 2) {
      return ChatView(key: const ValueKey('chat'), trans: widget.trans, isDarkMode: widget.isDarkMode, apiService: _apiService);
    } else if (_currentIndex == 3) {
      return PredictView(key: const ValueKey('predict'), trans: widget.trans, isDarkMode: widget.isDarkMode, apiService: _apiService);
    } else if (_currentIndex == 4) {
      return LogbookView(key: const ValueKey('logbook'), trans: widget.trans, isDarkMode: widget.isDarkMode, apiService: _apiService);
    } else {
      switch (_innerMode) {
        case 2:
          return WeatherView(key: const ValueKey('weather'), trans: widget.trans, isDarkMode: widget.isDarkMode, apiService: _apiService);
        case 3:
          return IrrigationView(key: const ValueKey('irrigation'), trans: widget.trans, isDarkMode: widget.isDarkMode, apiService: _apiService);
        case 4:
          return GuidesView(key: const ValueKey('guides'), trans: widget.trans, isDarkMode: widget.isDarkMode, apiService: _apiService);
        default:
          return DashboardView(key: const ValueKey('dashboard'), trans: widget.trans, isDarkMode: widget.isDarkMode, onModeChange: _onModeChange);
      }
    }
  }

  Widget _buildSideDrawer() {
    final Color bgColor = widget.isDarkMode ? const Color(0xFF111111) : Colors.white;
    final Color textColor = widget.isDarkMode ? Colors.white : Colors.black87;

    return Drawer(
      backgroundColor: bgColor,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.isDarkMode 
                  ? [Colors.greenAccent.withOpacity(0.2), Colors.black] 
                  : [Colors.green.shade200, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(radius: 35, backgroundColor: Colors.greenAccent, child: Icon(Icons.agriculture, size: 40, color: Colors.white)),
                const SizedBox(height: 15),
                Text("Smart Farm", style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold)),
                Text("Admin User", style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 14)),
              ],
            ),
          ),
          
          ListTile(
            leading: const Icon(Icons.language, color: Colors.blueAccent),
            title: Text(widget.trans['change_language'] ?? "Change Language", style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                backgroundColor: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                builder: (context) => Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 40, height: 5, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(10))),
                      ListTile(title: Text("العربية", style: TextStyle(color: textColor)), onTap: () { widget.onLangChange('ar'); Navigator.pop(context); }),
                      ListTile(title: Text("English", style: TextStyle(color: textColor)), onTap: () { widget.onLangChange('en'); Navigator.pop(context); }),
                      ListTile(title: Text("Français", style: TextStyle(color: textColor)), onTap: () { widget.onLangChange('fr'); Navigator.pop(context); }),
                    ],
                  ),
                ),
              );
            },
          ),
          
          SwitchListTile(
            title: Text(widget.isDarkMode ? (widget.trans['light_mode'] ?? "Light Mode") : (widget.trans['dark_mode'] ?? "Dark Mode"), style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
            value: widget.isDarkMode,
            onChanged: (val) {
              widget.onThemeChange(val);
              Navigator.pop(context);
            },
            activeColor: Colors.greenAccent,
            secondary: Icon(widget.isDarkMode ? Icons.nightlight_round : Icons.wb_sunny, color: widget.isDarkMode ? Colors.yellow : Colors.orange),
          ),
          
          const Spacer(),
          const Divider(),
          
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: Text(widget.trans['logout'] ?? "Logout", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            onTap: () {
              _apiService.logout().then((_) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => Scaffold(
                      backgroundColor: widget.isDarkMode ? const Color(0xFF0D110D) : const Color(0xFFF4F7F4),
                      body: const Center(child: Text("Restart app to login again.")),
                    ),
                  ),
                  (Route<dynamic> route) => false,
                );
              });
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _onPopInvoked(bool didPop, dynamic result) async {
    if (didPop) return;
    final bool shouldPop = await _onWillPop();
    if (shouldPop && context.mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onPopInvoked,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: widget.isDarkMode ? const Color(0xFF0D110D) : const Color(0xFFF4F7F4),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text("AgriSmart AI", style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          leading: IconButton(
            icon: Icon(Icons.menu_rounded, color: widget.isDarkMode ? Colors.white : Colors.black87, size: 28),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
        ),
        drawer: _buildSideDrawer(),
        body: SafeArea(
          child: Column(
            children: [
              if (_currentIndex == 0 && _innerMode == 0) _buildHeader(),
              
              if (_currentIndex == 0 && _innerMode != 0)
                Padding(
                  padding: const EdgeInsets.only(left: 15, right: 15, bottom: 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: widget.isDarkMode ? Colors.greenAccent : Colors.green[700],
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                      label: const Text("Back", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      onPressed: () => _onModeChange(0),
                    ),
                  ),
                ),

              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeIn,
                  switchOutCurve: Curves.easeOut,
                  child: _buildCurrentPageContent(),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: widget.isDarkMode ? Colors.black54 : Colors.grey.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _onBottomNavTapped,
              backgroundColor: widget.isDarkMode ? const Color(0xFF151A15) : Colors.white,
              selectedItemColor: Colors.greenAccent[400],
              unselectedItemColor: widget.isDarkMode ? Colors.white54 : Colors.grey[500],
              showUnselectedLabels: true,
              type: BottomNavigationBarType.fixed,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.home_rounded),
                  activeIcon: const Icon(Icons.home_rounded, size: 26),
                  label: widget.trans['menu'] ?? 'Home',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.agriculture_rounded),
                  activeIcon: const Icon(Icons.agriculture_rounded, size: 26),
                  label: widget.trans['farming_settings'] ?? 'Farms',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.chat_bubble_rounded),
                  activeIcon: const Icon(Icons.chat_bubble_rounded, size: 26),
                  label: widget.trans['chat'] ?? 'Chat',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.auto_awesome_rounded),
                  activeIcon: const Icon(Icons.auto_awesome_rounded, size: 26),
                  label: widget.trans['harvest_prediction'] ?? 'Predict',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.menu_book_rounded),
                  activeIcon: const Icon(Icons.menu_book_rounded, size: 26),
                  label: widget.trans['farming_log'] ?? 'Logbook',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

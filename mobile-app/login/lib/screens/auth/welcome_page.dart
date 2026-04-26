import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math'; // For particle math
import 'login_page.dart';
import 'signup_page.dart';

class WelcomePage extends StatefulWidget {
  final Map<String, String> trans;
  final Function(String) onLangChange;
  final bool isDarkMode; 
  final Function(bool) onThemeChange; 

  const WelcomePage({
    super.key, 
    required this.trans, 
    required this.onLangChange,
    required this.isDarkMode,
    required this.onThemeChange,
  });

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> with TickerProviderStateMixin {
  late String _fullText;
  List<String> _words = [];
  int _startWordIndex = 0; 
  int _endWordIndex = 0;   
  bool _isDeleting = false;
  Timer? _timer;

  late AnimationController _pulseController;
  late AnimationController _backgroundController;

  @override
  void initState() {
    super.initState();
    _fullText = widget.trans['welcome'] ?? "Welcome to Smart Farm";
    _words = _fullText.split(" ");
    _startAnimation();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void didUpdateWidget(WelcomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trans != widget.trans) {
      setState(() {
        _fullText = widget.trans['welcome'] ?? "Welcome to Smart Farm";
        _words = _fullText.split(" ");
        _startWordIndex = 0;
        _endWordIndex = 0;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  void _startAnimation() {
    _timer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      if (!mounted) return;
      setState(() {
        if (!_isDeleting) {
          if (_endWordIndex < _words.length) {
            _endWordIndex++;
          } else {
            Future.delayed(const Duration(milliseconds: 1200), () {
              if (mounted) setState(() => _isDeleting = true);
            });
          }
        } else {
          if (_startWordIndex < _endWordIndex) {
            _startWordIndex++;
          } else {
            _startWordIndex = 0;
            _endWordIndex = 0;
            _isDeleting = false;
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor = widget.isDarkMode ? Colors.white : Colors.black87;
    // Set particle and halo color based on theme for visibility
    final Color effectColor = widget.isDarkMode 
        ? Colors.greenAccent 
        : const Color(0xFF2E7D32); // Dark green for light mode

    String displayedText = _words.sublist(_startWordIndex, _endWordIndex).join(" ");

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.language, color: Colors.orangeAccent),
            onPressed: () {
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
                      ListTile(title: Text("العربية", style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black)), onTap: () { widget.onLangChange('ar'); Navigator.pop(context); }),
                      ListTile(title: Text("English", style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black)), onTap: () { widget.onLangChange('en'); Navigator.pop(context); }),
                      ListTile(title: Text("Français", style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black)), onTap: () { widget.onLangChange('fr'); Navigator.pop(context); }),
                    ],
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(
              widget.isDarkMode ? Icons.dark_mode : Icons.light_mode, 
              color: Colors.orangeAccent
            ),
            onPressed: () => widget.onThemeChange(!widget.isDarkMode),
          )
        ],
      ),
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(seconds: 2),
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: widget.isDarkMode 
                    ? [const Color(0xFF0A2E10), Colors.black, const Color(0xFF1B5E20)] 
                    : [const Color(0xFFA8E6CF), Colors.white, const Color(0xFFDCEDC1)], 
              ),
            ),
          ),

          // 2. Floating particles (color modified here)
          ...List.generate(10, (index) => _buildFloatingParticle(index, effectColor)),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Pulsing icon (halo color modified here)
                ScaleTransition(
                  scale: Tween(begin: 1.0, end: 1.1).animate(
                    CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // Halo becomes clearer in light mode
                      color: effectColor.withOpacity(widget.isDarkMode ? 0.1 : 0.15),
                    ),
                    child: Icon(Icons.eco_rounded, size: 100, color: effectColor),
                  ),
                ),
                const SizedBox(height: 50),
                
                SizedBox(
                  height: 60,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Text(
                      displayedText,
                      key: ValueKey<String>(displayedText),
                      style: TextStyle(
                        fontSize: 28, 
                        fontWeight: FontWeight.w900, 
                        color: textColor,
                        letterSpacing: 1.2,
                      ), 
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                
                const SizedBox(height: 60),
                
                _buildFancyBtn(context, widget.trans['login'] ?? "تسجيل الدخول", "login", true),
                const SizedBox(height: 20),
                _buildFancyBtn(context, widget.trans['signup'] ?? "إنشاء حساب", "signup", false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Modify function to accept appropriate color
  Widget _buildFloatingParticle(int index, Color color) {
    final random = Random(index);
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) {
        return Positioned(
          left: random.nextDouble() * MediaQuery.of(context).size.width,
          top: (random.nextDouble() * MediaQuery.of(context).size.height + (_backgroundController.value * 100 * (index % 2 == 0 ? 1 : -1))) % MediaQuery.of(context).size.height,
          child: Container(
            width: random.nextDouble() * 15 + 5,
            height: random.nextDouble() * 15 + 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // Higher transparency in light mode to make spheres more elegant
              color: color.withOpacity(widget.isDarkMode ? 0.15 : 0.2),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFancyBtn(BuildContext context, String text, String target, bool isFull) {
    // Modify colors to fit light mode more clearly
    final Color primaryBtnColor = widget.isDarkMode ? Colors.greenAccent : const Color(0xFF4CAF50);
    final Color outlineColor = widget.isDarkMode ? Colors.greenAccent : const Color(0xFF1B5E20);

    return Container(
      width: 280,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: isFull ? [
          BoxShadow(
            color: (widget.isDarkMode ? Colors.greenAccent : Colors.green).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ] : [],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isFull ? primaryBtnColor : Colors.white.withOpacity(widget.isDarkMode ? 0.05 : 0.8),
          foregroundColor: isFull ? Colors.black : outlineColor,
          side: BorderSide(color: outlineColor, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 0,
        ),
        onPressed: () {
          Widget nextPage = target == "login" 
            ? LoginPage(trans: widget.trans, onLangChange: widget.onLangChange, isDarkMode: widget.isDarkMode, onThemeChange: widget.onThemeChange)
            : SignUpPage(trans: widget.trans, onLangChange: widget.onLangChange, isDarkMode: widget.isDarkMode, onThemeChange: widget.onThemeChange);
          
          Navigator.push(context, MaterialPageRoute(builder: (context) => nextPage));
        },
        child: Text(
          text, 
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)
        ),
      ),
    );
  }
}
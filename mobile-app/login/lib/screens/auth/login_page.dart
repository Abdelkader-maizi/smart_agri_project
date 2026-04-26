import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../home/main_page.dart';

class LoginPage extends StatefulWidget {
  final Map<String, String> trans;
  final Function(String) onLangChange;
  final bool isDarkMode;
  final Function(bool) onThemeChange;

  const LoginPage({
    super.key,
    required this.trans,
    required this.onLangChange,
    required this.isDarkMode,
    required this.onThemeChange,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  late bool _localDarkMode;
  bool _obscurePass = true;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _localDarkMode = widget.isDarkMode;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validatePass(String v) =>
      RegExp(r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,22}$').hasMatch(v);

  bool _validateEmail(String v) =>
      RegExp(r'^[a-zA-Z0-9._%+-]+@(gmail|yahoo|hotmail|outlook)\.(com|net|org)$')
          .hasMatch(v.toLowerCase());

  void _onLoginPressed() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        LoginRequested(
          identifier: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color topColor = _localDarkMode ? const Color(0xFF0F172A) : const Color(0xFF1B5E20);
    final Color bottomColor = _localDarkMode ? const Color(0xFF020617) : const Color(0xFF4CAF50);
    final Color mainGreen = Colors.greenAccent[400]!;

    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MainPage(
                  trans: widget.trans,
                  onLangChange: widget.onLangChange,
                  isDarkMode: _localDarkMode,
                  onThemeChange: widget.onThemeChange,
                ),
              ),
            );
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        },
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [topColor, bottomColor],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -100,
                right: -50,
                child: _buildBlurCircle(mainGreen.withOpacity(0.15), 300),
              ),
              Positioned(
                bottom: 100,
                left: -50,
                child: _buildBlurCircle(Colors.white.withOpacity(0.05), 200),
              ),
              
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 120),
                        
                        Text(
                          widget.trans['login']!,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            shadows: [
                              Shadow(
                                blurRadius: 20,
                                color: mainGreen.withOpacity(0.8),
                                offset: const Offset(0, 0),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          "Smart Farming Experience",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 14,
                            letterSpacing: 3,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        const SizedBox(height: 80),

                        // Removed name field from login as per auth flow (only identifier/password needed)
                        _buildGlassField(
                          label: widget.trans['email'] ?? "Email/Phone",
                          icon: Icons.alternate_email_rounded,
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
                        ),
                        const SizedBox(height: 20),
                        _buildGlassField(
                          label: widget.trans['pass']!,
                          icon: Icons.lock_open_rounded,
                          controller: _passwordController,
                          isPassword: true,
                          obscureText: _obscurePass,
                          onTogglePass: () => setState(() => _obscurePass = !_obscurePass),
                          validator: (v) => (v == null || v.isEmpty) ? widget.trans['pass_error'] : null,
                        ),
                        
                        const SizedBox(height: 60),

                        BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, state) {
                            if (state is AuthLoading) {
                              return const Center(
                                child: CircularProgressIndicator(color: Colors.greenAccent),
                              );
                            }
                            return InkWell(
                              onTap: _onLoginPressed,
                              borderRadius: BorderRadius.circular(25),
                              child: Container(
                                height: 65,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [mainGreen, const Color(0xFF00C853)],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: mainGreen.withOpacity(0.4),
                                      blurRadius: 25,
                                      offset: const Offset(0, 10),
                                    )
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    widget.trans['login']!.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 30),
                        
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                              children: [
                                const TextSpan(text: "Don't have an account? "),
                                TextSpan(
                                  text: "Sign Up",
                                  style: TextStyle(
                                    color: mainGreen,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
              
              Positioned(
                top: 20,
                left: 10,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              Positioned(
                top: 20,
                right: 70,
                child: IconButton(
                  icon: const Icon(Icons.language, color: Colors.white),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: _localDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                      builder: (context) => Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 40, height: 5, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(10))),
                            ListTile(title: Text("العربية", style: TextStyle(color: _localDarkMode ? Colors.white : Colors.black)), onTap: () { widget.onLangChange('ar'); Navigator.pop(context); }),
                            ListTile(title: Text("English", style: TextStyle(color: _localDarkMode ? Colors.white : Colors.black)), onTap: () { widget.onLangChange('en'); Navigator.pop(context); }),
                            ListTile(title: Text("Français", style: TextStyle(color: _localDarkMode ? Colors.white : Colors.black)), onTap: () { widget.onLangChange('fr'); Navigator.pop(context); }),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              Positioned(
                top: 20,
                right: 20,
                child: IconButton(
                  icon: Icon(
                    _localDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() => _localDarkMode = !_localDarkMode);
                    widget.onThemeChange(_localDarkMode);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlurCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Container(color: Colors.transparent),
      ),
    );
  }

  Widget _buildGlassField({
    required String label,
    required IconData icon,
    TextEditingController? controller,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTogglePass,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
        prefixIcon: Icon(icon, color: Colors.greenAccent),
        suffixIcon: isPassword 
            ? IconButton(
                icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: Colors.white38),
                onPressed: onTogglePass,
              )
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        contentPadding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.greenAccent, width: 2),
        ),
        errorStyle: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.orangeAccent),
        ),
      ),
      validator: validator,
    );
  }
}
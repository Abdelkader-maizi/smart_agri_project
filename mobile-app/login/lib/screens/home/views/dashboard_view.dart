import 'package:flutter/material.dart';

class DashboardView extends StatelessWidget {
  final Map<String, String> trans;
  final bool isDarkMode;
  final Function(int) onModeChange;
  // Modes: 2=Weather, 3=Irrigation, 4=Fertilizer (Guides)

  const DashboardView({
    super.key,
    required this.trans,
    required this.isDarkMode,
    required this.onModeChange,
  });

  Widget _card(String title, IconData icon, List<Color> gradientColors, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
          border: Border.all(
            color: Colors.white.withOpacity(isDarkMode ? 0.1 : 0.5),
            width: 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(icon, size: 100, color: Colors.white.withOpacity(0.15)),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(icon, size: 32, color: Colors.white),
                    ),
                    const Spacer(),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return SingleChildScrollView(
      key: const ValueKey(1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Full width header image - Algeria 3D Map
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            height: screenHeight * 0.28,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: isDarkMode ? Colors.greenAccent.withOpacity(0.1) : Colors.green.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
              image: const DecorationImage(
                image: AssetImage('assets/images/algeria_3d_map.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.4), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
              padding: const EdgeInsets.all(20),
              alignment: Alignment.bottomLeft,
              child: Text(
                trans['algeria_map'] ?? "Algeria Map",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
            child: Text(
              trans['quick_tools'] ?? "Quick Tools",
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black54,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          // Actions grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 0.85,
              children: [
                _card(
                  trans['weather_data'] ?? "Weather Data", 
                  Icons.thermostat_rounded, 
                  [const Color(0xFFF2994A), const Color(0xFFF2C94C)], 
                  () => onModeChange(2)
                ),
                _card(
                  trans['irrigation_schedule'] ?? "Irrigation", 
                  Icons.water_drop_rounded, 
                  [const Color(0xFF56CCF2), const Color(0xFF2F80ED)], 
                  () => onModeChange(3)
                ),
                _card(
                  trans['fertilizer_guide'] ?? "Guides", 
                  Icons.science_rounded, 
                  [const Color(0xFF11998E), const Color(0xFF38EF7D)], 
                  () => onModeChange(4)
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

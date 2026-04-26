import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../services/api_service.dart';

class WeatherView extends StatefulWidget {
  final Map<String, String> trans;
  final bool isDarkMode;
  final ApiService apiService;

  const WeatherView({
    super.key,
    required this.trans,
    required this.isDarkMode,
    required this.apiService,
  });

  @override
  State<WeatherView> createState() => _WeatherViewState();
}

class _WeatherViewState extends State<WeatherView> {
  bool _isLoading = true;
  List<dynamic> _farms = [];
  int? _selectedFarmId;
  Map<String, dynamic>? _weatherData;
  String? _error;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _fetchFarms();
  }

  Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }
    
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _fetchFarms() async {
    final res = await widget.apiService.getFarms();
    if (mounted) {
      setState(() {
        if (res['success'] == true && res['farms'] != null && (res['farms'] as List).isNotEmpty) {
          _farms = res['farms'];
          _selectedFarmId = _farms.first['id'];
          _fetchWeather();
        } else {
          // If no farms, try GPS
          _selectedFarmId = null;
          _fetchWeather();
        }
      });
    }
  }

  Future<void> _fetchWeather() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    Map<String, dynamic> res;

    if (_selectedFarmId != null) {
      res = await widget.apiService.getWeather(_selectedFarmId, null, null);
    } else {
      _currentPosition = await _determinePosition();
      if (_currentPosition != null) {
        res = await widget.apiService.getWeather(null, _currentPosition!.latitude, _currentPosition!.longitude);
      } else {
        setState(() {
          _isLoading = false;
          _error = "Please add a farm or enable GPS to view weather.";
        });
        return;
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res['success'] == true) {
          _weatherData = res['data'];
        } else {
          _error = res['error'] ?? "Failed to fetch weather.";
        }
      });
    }
  }

  Widget _card(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: widget.isDarkMode ? [] : [const BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: 10),
          Text(title, style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center),
          const SizedBox(height: 5),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
       return const Center(child: CircularProgressIndicator(color: Colors.orangeAccent));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 16), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
                icon: const Icon(Icons.refresh, color: Colors.black),
                label: Text(widget.trans['retry_gps'] ?? "Retry via GPS", style: const TextStyle(color: Colors.black)),
                onPressed: _fetchWeather,
              )
            ],
          ),
        )
      );
    }

    if (_weatherData == null) {
      return const SizedBox.shrink();
    }

    final double temp = (_weatherData!['temperature'] as num).toDouble();
    final double hum = (_weatherData!['humidity'] as num).toDouble();
    final double wind = (_weatherData!['wind_speed'] as num).toDouble();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            if (_farms.isNotEmpty)
              DropdownButtonFormField<int>(
                initialValue: _selectedFarmId,
                dropdownColor: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: widget.trans['select_farm'] ?? "Select Farm",
                  labelStyle: TextStyle(color: widget.isDarkMode ? Colors.white60 : Colors.black54),
                  prefixIcon: const Icon(Icons.location_on, color: Colors.orangeAccent),
                ),
                items: [
                  DropdownMenuItem<int>(
                    value: -1,
                    child: Text(widget.trans['current_gps'] ?? "Current Location (GPS)"),
                  ),
                  ..._farms.map((f) => DropdownMenuItem<int>(
                    value: f['id'],
                    child: Text(f['name']),
                  )),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedFarmId = val == -1 ? null : val);
                    _fetchWeather();
                  }
                },
              )
            else
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.gps_fixed, color: Colors.blueAccent),
                    const SizedBox(width: 10),
                    Expanded(child: Text(widget.trans['using_gps'] ?? "Using Current GPS Location", style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black))),
                  ],
                ),
              ),
            const SizedBox(height: 25),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              children: [
                _card(widget.trans['temperature'] ?? "Temperature", "$temp°C", Icons.thermostat_auto_rounded, temp > 30 ? Colors.redAccent : Colors.orangeAccent),
                _card(widget.trans['humidity'] ?? "Humidity", "$hum%", Icons.water_rounded, hum < 40 ? Colors.brown : Colors.blueAccent),
                _card(widget.trans['wind_speed'] ?? "Wind Speed", "$wind km/h", Icons.air_rounded, Colors.blueGrey),
                _card(widget.trans['rainfall'] ?? "Rainfall", "${_weatherData!['rainfall']} mm", Icons.grain_rounded, Colors.cyan),
              ],
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                minimumSize: const Size.fromHeight(50)
              ),
              icon: const Icon(Icons.refresh, color: Colors.black),
              label: Text(widget.trans['refresh_data'] ?? "Refresh data", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              onPressed: _fetchWeather,
            )
          ],
        ),
      ),
    );
  }
}

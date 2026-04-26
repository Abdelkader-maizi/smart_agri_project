import 'package:flutter/material.dart';
import '../../../../services/api_service.dart';

class IrrigationView extends StatefulWidget {
  final Map<String, String> trans;
  final bool isDarkMode;
  final ApiService apiService;

  const IrrigationView({
    super.key,
    required this.trans,
    required this.isDarkMode,
    required this.apiService,
  });

  @override
  State<IrrigationView> createState() => _IrrigationViewState();
}

class _IrrigationViewState extends State<IrrigationView> {
  bool _isLoading = true;
  List<dynamic> _farms = [];
  int? _selectedFarmId;
  String? _error;
  Map<String, dynamic>? _result;

  final TextEditingController _cropCtrl = TextEditingController();
  final TextEditingController _areaCtrl = TextEditingController(text: "1.0");
  String _selectedSoil = "loamy";
  String _selectedWaterNeed = "medium";

  @override
  void initState() {
    super.initState();
    _fetchFarms();
  }

  Future<void> _fetchFarms() async {
    final res = await widget.apiService.getFarms();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res['success'] == true && res['farms'] != null && (res['farms'] as List).isNotEmpty) {
          _farms = res['farms'];
          _selectedFarmId = _farms.first['id'];
        } else {
          _error = "Please add a farm first to use Irrigation Recommendations.";
        }
      });
    }
  }

  Future<void> _getRecommendation() async {
    final crop = _cropCtrl.text.trim();
    final area = double.tryParse(_areaCtrl.text.trim());

    if (_selectedFarmId == null || crop.isEmpty || area == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields accurately.")),
      );
      return;
    }

    setState(() {
       _isLoading = true;
       _result = null;
       _error = null;
    });

    final payload = {
      "farm_id": _selectedFarmId!,
      "crop_name": crop,
      "water_need": _selectedWaterNeed,
      "soil_type": _selectedSoil,
      "farm_area_hectares": area
    };

    final res = await widget.apiService.getIrrigation(payload);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res['success'] == true) {
          _result = res['data'];
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Schedule generated & saved!")),
          );
        } else {
          _error = res['error'] ?? "Failed to fetch AI recommendation.";
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.cyan));
    }

    final Color bgColor = widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final Color textColor = widget.isDarkMode ? Colors.white : Colors.black87;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.trans['smart_irrigation'] ?? "Smart Irrigation (AI)", style: const TextStyle(color: Colors.cyan, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 16)),
            ),
            
          if (_farms.isNotEmpty) ...[
            DropdownButtonFormField<int>(
              value: _selectedFarmId,
              dropdownColor: bgColor,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: widget.trans['select_farm'] ?? "Select Farm (for auto weather)",
                labelStyle: TextStyle(color: widget.isDarkMode ? Colors.white60 : Colors.black54),
                prefixIcon: const Icon(Icons.location_on, color: Colors.cyan),
              ),
              items: _farms.map((f) => DropdownMenuItem<int>(
                value: f['id'],
                child: Text(f['name']),
              )).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedFarmId = val);
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _cropCtrl,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(labelText: widget.trans['crop_name'] ?? "Crop Name", prefixIcon: const Icon(Icons.grass)),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedSoil,
                    dropdownColor: bgColor,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(labelText: widget.trans['soil_type'] ?? "Soil Type"),
                    items: [
                      DropdownMenuItem(value: "sandy", child: Text(widget.trans['sandy'] ?? "Sandy")),
                      DropdownMenuItem(value: "loamy", child: Text(widget.trans['loamy'] ?? "Loamy")),
                      DropdownMenuItem(value: "clay", child: Text(widget.trans['clay'] ?? "Clay")),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedSoil = val);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedWaterNeed,
                    dropdownColor: bgColor,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(labelText: widget.trans['water_need'] ?? "Water Need"),
                    items: [
                      DropdownMenuItem(value: "low", child: Text(widget.trans['low'] ?? "Low")),
                      DropdownMenuItem(value: "medium", child: Text(widget.trans['medium'] ?? "Medium")),
                      DropdownMenuItem(value: "high", child: Text(widget.trans['high'] ?? "High")),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedWaterNeed = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _areaCtrl,
              keyboardType: TextInputType.number,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(labelText: widget.trans['area'] ?? "Farm Area (Hectares)", prefixIcon: const Icon(Icons.aspect_ratio)),
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan,
                minimumSize: const Size.fromHeight(50)
              ),
              icon: const Icon(Icons.auto_awesome, color: Colors.black),
              label: Text(widget.trans['generate_schedule'] ?? "Generate AI Schedule", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              onPressed: _getRecommendation,
            ),
          ],
          
          if (_result != null) ...[
            const SizedBox(height: 30),
            Card(
              color: bgColor,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${widget.trans['result_for'] ?? 'Result for'} ${_result!['crop']}", style: const TextStyle(color: Colors.cyan, fontSize: 16, fontWeight: FontWeight.bold)),
                    const Divider(),
                    Text("${widget.trans['daily_water_need'] ?? 'Daily Water Need'}: ${_result!['daily_water_need_mm']} mm", style: TextStyle(color: textColor)),
                    const SizedBox(height: 5),
                    Text("${widget.trans['total_required'] ?? 'Total required'}: ${_result!['total_liters_per_day']} ${widget.trans['liters_day'] ?? 'Liters/day'}", style: TextStyle(color: textColor)),
                    const SizedBox(height: 15),
                    Text(widget.trans['recommended_method'] ?? "Recommended Method:", style: TextStyle(color: Colors.grey[400])),
                    Text(_result!['recommended_method'], style: TextStyle(color: Colors.greenAccent[400], fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            )
          ]
        ],
      ),
    );
  }
}

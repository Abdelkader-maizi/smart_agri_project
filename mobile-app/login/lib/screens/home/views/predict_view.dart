import 'package:flutter/material.dart';
import '../../../../services/api_service.dart';

class PredictView extends StatefulWidget {
  final Map<String, String> trans;
  final bool isDarkMode;
  final ApiService apiService;

  const PredictView({
    super.key,
    required this.trans,
    required this.isDarkMode,
    required this.apiService,
  });

  @override
  State<PredictView> createState() => _PredictViewState();
}

class _PredictViewState extends State<PredictView> {
  bool _isLoading = true;
  List<dynamic> _farms = [];
  int? _selectedFarmId;
  String? _error;
  Map<String, dynamic>? _result;

  String _selectedCrop = 'Wheat';
  final List<String> _commonCrops = [
    'Wheat', 'Barley', 'Potato', 'Tomato', 'Onion', 
    'Garlic', 'Carrot', 'Corn', 'Olive', 'Citrus',
    'Dates', 'Apple', 'Grapes', 'Watermelon'
  ];
  final TextEditingController _areaCtrl = TextEditingController(text: "1.0");
  final TextEditingController _nCtrl = TextEditingController();
  final TextEditingController _pCtrl = TextEditingController();
  final TextEditingController _kCtrl = TextEditingController();
  final TextEditingController _phCtrl = TextEditingController();
  
  String _season = "spring";

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
          _autoFillSoilData(_farms.first['city']);
        } else {
          _error = "Please add a farm first from the Farm Manager.";
        }
      });
    }
  }

  void _autoFillSoilData(String? city) {
    if (city == null || city.isEmpty) return;
    
    // Default estimated values per region
    Map<String, Map<String, String>> cityData = {
      "algiers": {"n": "80", "p": "40", "k": "40", "ph": "7.2"},
      "medea": {"n": "60", "p": "30", "k": "35", "ph": "6.8"},
      "oran": {"n": "70", "p": "45", "k": "50", "ph": "7.5"},
      "ouargla": {"n": "30", "p": "20", "k": "60", "ph": "8.1"},
      "setif": {"n": "85", "p": "50", "k": "45", "ph": "7.0"},
      "constantine": {"n": "75", "p": "45", "k": "40", "ph": "7.1"},
      "adrar": {"n": "25", "p": "15", "k": "55", "ph": "8.2"},
    };

    String key = city.toLowerCase();
    Map<String, String>? data;
    
    // Simple matching
    for (var k in cityData.keys) {
      if (key.contains(k)) {
        data = cityData[k];
        break;
      }
    }

    // Default if not found
    data ??= {"n": "50", "p": "30", "k": "40", "ph": "7.0"};

    setState(() {
      _nCtrl.text = data!["n"]!;
      _pCtrl.text = data["p"]!;
      _kCtrl.text = data["k"]!;
      _phCtrl.text = data["ph"]!;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Auto-filled soil data for $city")),
    );
  }

  Future<void> _predictYield() async {
    final crop = _selectedCrop;
    final area = double.tryParse(_areaCtrl.text.trim());
    final n = double.tryParse(_nCtrl.text.trim());
    final p = double.tryParse(_pCtrl.text.trim());
    final k = double.tryParse(_kCtrl.text.trim());
    final ph = double.tryParse(_phCtrl.text.trim());

    if (_selectedFarmId == null || crop.isEmpty || area == null || n == null || p == null || k == null || ph == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please completely fill all fields with numbers where appropriate.")),
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
      "season": _season,
      "nitrogen": n,
      "phosphorus": p,
      "potassium": k,
      "ph": ph,
      "farm_area_hectares": area
    };

    final res = await widget.apiService.getYieldPrediction(payload);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res['success'] == true) {
          _result = res['data'];
        } else {
          _error = res['error'] ?? "Failed to fetch AI Prediction.";
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.purpleAccent));
    }

    final Color bgColor = widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final Color textColor = widget.isDarkMode ? Colors.white : Colors.black87;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.trans['predict_yield'] ?? "Harvest AI Predictor", style: const TextStyle(color: Colors.purpleAccent, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 16)),
            ),
            
          if (_farms.isNotEmpty) ...[
            DropdownButtonFormField<int>(
              initialValue: _selectedFarmId,
              dropdownColor: bgColor,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: widget.trans['select_farm'] ?? "Select Farm (Weather uses live farm loc)",
                labelStyle: TextStyle(color: widget.isDarkMode ? Colors.white60 : Colors.black54),
                prefixIcon: const Icon(Icons.location_on, color: Colors.purpleAccent),
              ),
              items: _farms.map((f) => DropdownMenuItem<int>(
                value: f['id'],
                child: Text(f['name']),
              )).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedFarmId = val);
                  final selectedFarm = _farms.firstWhere((f) => f['id'] == val, orElse: () => null);
                  if (selectedFarm != null) {
                    _autoFillSoilData(selectedFarm['city']);
                  }
                }
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedCrop,
                    dropdownColor: bgColor,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(labelText: widget.trans['crop_name'] ?? "Crop Name", prefixIcon: const Icon(Icons.grass)),
                    items: _commonCrops.map((c) => DropdownMenuItem(value: c, child: Text(widget.trans['crop_${c.toLowerCase()}'] ?? c))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCrop = val);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _season,
                    dropdownColor: bgColor,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(labelText: widget.trans['season'] ?? "Season"),
                    items: [
                      DropdownMenuItem(value: "spring", child: Text(widget.trans['spring'] ?? "Spring")),
                      DropdownMenuItem(value: "summer", child: Text(widget.trans['summer'] ?? "Summer")),
                      DropdownMenuItem(value: "autumn", child: Text(widget.trans['autumn'] ?? "Autumn")),
                      DropdownMenuItem(value: "winter", child: Text(widget.trans['winter'] ?? "Winter")),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _season = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: TextField(controller: _nCtrl, keyboardType: TextInputType.number, style: TextStyle(color: textColor), decoration: InputDecoration(labelText: widget.trans['nitrogen'] ?? "Nitrogen (N)"))),
                const SizedBox(width: 5),
                Expanded(child: TextField(controller: _pCtrl, keyboardType: TextInputType.number, style: TextStyle(color: textColor), decoration: InputDecoration(labelText: widget.trans['phosphorus'] ?? "Phosphorus (P)"))),
                const SizedBox(width: 5),
                Expanded(child: TextField(controller: _kCtrl, keyboardType: TextInputType.number, style: TextStyle(color: textColor), decoration: InputDecoration(labelText: widget.trans['potassium'] ?? "Potassium (K)"))),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: TextField(controller: _phCtrl, keyboardType: TextInputType.number, style: TextStyle(color: textColor), decoration: InputDecoration(labelText: widget.trans['soil_ph'] ?? "Soil pH (0-14)"))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: _areaCtrl, keyboardType: TextInputType.number, style: TextStyle(color: textColor), decoration: InputDecoration(labelText: widget.trans['area'] ?? "Area (Hectares)"))),
              ],
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purpleAccent,
                minimumSize: const Size.fromHeight(50)
              ),
              icon: const Icon(Icons.query_stats, color: Colors.black),
              label: Text(widget.trans['predict_yield'] ?? "Predict Yield", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              onPressed: _predictYield,
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
                    Row(
                      children: [
                        const Icon(Icons.insights, color: Colors.purpleAccent),
                        const SizedBox(width: 10),
                        Text(widget.trans['predicted_yield'] ?? "Predicted Yield", style: const TextStyle(color: Colors.purpleAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(),
                    Text("${widget.trans['predicted_tons'] ?? 'Predicted Tons'}: ${_result!['predicted_yield_tons']}", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 5),
                    Text("${widget.trans['yield_range'] ?? 'Yield Range'}: ${_result!['yield_range']['low_tons']} - ${_result!['yield_range']['high_tons']} ${widget.trans['tons'] ?? 'tons'}", style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 15),
                    Text(widget.trans['quality_rating'] ?? "Quality Rating:", style: TextStyle(color: Colors.grey[400])),
                    Text(widget.trans['quality_${_result!['quality_rating']}'] ?? _result!['quality_message'] ?? _result!['quality_rating'], style: TextStyle(color: Colors.greenAccent[400], fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    Text(widget.trans['top_improvement_tip'] ?? "Top Improvement Tip:", style: const TextStyle(color: Colors.orangeAccent)),
                    Text(widget.trans['tip_${_result!['weakest_factor']}'] ?? _result!['top_improvement'], style: TextStyle(color: textColor)),
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

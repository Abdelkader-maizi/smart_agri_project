import 'package:flutter/material.dart';
import '../../../../services/api_service.dart';

class GuidesView extends StatefulWidget {
  final Map<String, String> trans;
  final bool isDarkMode;
  final ApiService apiService;

  const GuidesView({
    super.key,
    required this.trans,
    required this.isDarkMode,
    required this.apiService,
  });

  @override
  State<GuidesView> createState() => _GuidesViewState();
}

class _GuidesViewState extends State<GuidesView> {
  bool _isLoading = true;
  List<dynamic> _fertilizers = [];
  List<dynamic> _calendar = [];
  String? _error;
  bool _showFertilizers = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final fertRes = await widget.apiService.getFertilizers();
    final calRes = await widget.apiService.getPlantingCalendar();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (fertRes['success'] == true && calRes['success'] == true) {
          _fertilizers = fertRes['manuals'] ?? [];
          _calendar = calRes['guides'] ?? [];
        } else {
          _error = fertRes['error'] ?? calRes['error'] ?? "Failed to fetch guides.";
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.green));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 16), textAlign: TextAlign.center),
        )
      );
    }

    final Color bgColor = widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final Color textColor = widget.isDarkMode ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChoiceChip(
                label: Text(widget.trans['fertilizers'] ?? "Fertilizers"),
                selected: _showFertilizers,
                onSelected: (val) => setState(() => _showFertilizers = true),
                selectedColor: Colors.greenAccent.withOpacity(0.3),
              ),
              const SizedBox(width: 15),
              ChoiceChip(
                label: Text(widget.trans['planting_calendar'] ?? "Planting Calendar"),
                selected: !_showFertilizers,
                onSelected: (val) => setState(() => _showFertilizers = false),
                selectedColor: Colors.blueAccent.withOpacity(0.3),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _showFertilizers
                ? ListView.builder(
                    itemCount: _fertilizers.length,
                    itemBuilder: (context, index) {
                      final item = _fertilizers[index];
                      return Card(
                        color: bgColor,
                        margin: const EdgeInsets.only(bottom: 15),
                        child: ListTile(
                          leading: const Icon(Icons.science, color: Colors.green),
                          title: Text("${item['item']} (${item['type']})", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(item['rule_ar'], style: const TextStyle(color: Colors.grey)),
                          ),
                        ),
                      );
                    },
                  )
                : ListView.builder(
                    itemCount: _calendar.length,
                    itemBuilder: (context, index) {
                      final item = _calendar[index];
                      final months = (item['recommended_months'] as List).join(", ");
                      return Card(
                        color: bgColor,
                        margin: const EdgeInsets.only(bottom: 15),
                        child: ListTile(
                          leading: const Icon(Icons.calendar_month, color: Colors.blueAccent),
                          title: Text("${item['crop']} (${item['name_ar']})", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("${widget.trans['months'] ?? 'Months'}: $months", style: const TextStyle(color: Colors.grey)),
                                const SizedBox(height: 5),
                                Text("${widget.trans['best_temp'] ?? 'Best Temp'}: ${item['best_temp']}°C", style: const TextStyle(color: Colors.blueGrey)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

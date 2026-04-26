import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../services/api_service.dart';

class LogbookView extends StatefulWidget {
  final Map<String, String> trans;
  final bool isDarkMode;
  final ApiService apiService;

  const LogbookView({
    super.key,
    required this.trans,
    required this.isDarkMode,
    required this.apiService,
  });

  @override
  State<LogbookView> createState() => _LogbookViewState();
}

class _LogbookViewState extends State<LogbookView> {
  bool _isLoading = true;
  List<dynamic> _logs = [];
  List<dynamic> _farms = [];
  int? _selectedFarmId;
  String? _error;

  final TextEditingController _activityCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();

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

    final farmRes = await widget.apiService.getFarms();
    final logRes = await widget.apiService.getLogbook();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (farmRes['success'] == true && logRes['success'] == true) {
          _farms = farmRes['farms'] ?? [];
          _logs = logRes['logs'] ?? [];
          if (_farms.isNotEmpty && _selectedFarmId == null) {
            _selectedFarmId = _farms.first['id'];
          }
        } else {
          _error = farmRes['error'] ?? logRes['error'] ?? "Failed to fetch data.";
        }
      });
    }
  }

  Future<void> _addLog() async {
    final activity = _activityCtrl.text.trim();
    final desc = _descCtrl.text.trim();

    if (_selectedFarmId == null || activity.isEmpty || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a farm and fill all fields.")),
      );
      return;
    }

    setState(() => _isLoading = true);
    final uuid = const Uuid().v4();
    final res = await widget.apiService.addLog(uuid, _selectedFarmId!, activity, desc);

    if (res['success'] == true) {
      _activityCtrl.clear();
      _descCtrl.clear();
      _fetchData();
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['error'] ?? "Failed to add log.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.deepOrangeAccent));
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.trans['add_new_log'] ?? "Add New Log", style: TextStyle(color: widget.isDarkMode ? Colors.deepOrangeAccent : Colors.deepOrange, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          if (_farms.isEmpty) 
             Text(widget.trans['add_farm_to_record'] ?? "Please add a farm first from the Farm Manager to record logs.", style: const TextStyle(color: Colors.redAccent))
          else ...[
            DropdownButtonFormField<int>(
              value: _selectedFarmId,
              dropdownColor: bgColor,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: widget.trans['select_farm'] ?? "Select Farm",
                labelStyle: TextStyle(color: widget.isDarkMode ? Colors.white60 : Colors.black54),
                prefixIcon: const Icon(Icons.location_on, color: Colors.deepOrangeAccent),
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
              controller: _activityCtrl,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(labelText: widget.trans['activity_type'] ?? "Activity Type (e.g. Irrigation, Planting)", prefixIcon: const Icon(Icons.task)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descCtrl,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(labelText: widget.trans['description'] ?? "Description", prefixIcon: const Icon(Icons.description)),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrangeAccent,
                minimumSize: const Size.fromHeight(50)
              ),
              onPressed: _addLog,
              child: Text(widget.trans['save_log'] ?? "Save Log", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
          
          const SizedBox(height: 30),
          Text("📜 ${widget.trans['recent_logs'] ?? 'Recent Logs'}", style: TextStyle(color: widget.isDarkMode ? Colors.deepOrangeAccent : Colors.deepOrange, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Expanded(
            child: _logs.isEmpty 
              ? Center(child: Text(widget.trans['no_logs'] ?? "No logs recorded yet.", style: const TextStyle(color: Colors.grey)))
              : ListView.builder(
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                return Card(
                  color: bgColor,
                  margin: const EdgeInsets.only(bottom: 15),
                  child: ListTile(
                    leading: const Icon(Icons.history, color: Colors.deepOrangeAccent),
                    title: Text(log['activity_type'], style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(log['description'], style: const TextStyle(color: Colors.grey)),
                          const SizedBox(height: 5),
                          Text("${widget.trans['date'] ?? 'Date:'} ${log['created_at'].toString().split('T').first}", style: const TextStyle(color: Colors.blueGrey, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../services/api_service.dart';

class FarmManagerView extends StatefulWidget {
  final Map<String, String> trans;
  final bool isDarkMode;
  final ApiService apiService;

  const FarmManagerView({
    super.key,
    required this.trans,
    required this.isDarkMode,
    required this.apiService,
  });

  @override
  State<FarmManagerView> createState() => _FarmManagerViewState();
}

class _FarmManagerViewState extends State<FarmManagerView> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _latCtrl = TextEditingController();
  final TextEditingController _lonCtrl = TextEditingController();
  
  String _selectedCity = 'Algiers';
  final List<String> _algerianCities = [
    'Adrar', 'Chlef', 'Laghouat', 'Oum El Bouaghi', 'Batna', 'Béjaïa', 'Biskra', 
    'Béchar', 'Blida', 'Bouira', 'Tamanrasset', 'Tébessa', 'Tlemcen', 'Tiaret', 
    'Tizi Ouzou', 'Algiers', 'Djelfa', 'Jijel', 'Sétif', 'Saïda', 'Skikda', 
    'Sidi Bel Abbès', 'Annaba', 'Guelma', 'Constantine', 'Médéa', 'Mostaganem', 
    'M\'Sila', 'Mascara', 'Ouargla', 'Oran', 'El Bayadh', 'Illizi', 
    'Bordj Bou Arréridj', 'Boumerdès', 'El Tarf', 'Tindouf', 'Tissemsilt', 
    'El Oued', 'Khenchela', 'Souk Ahras', 'Tipaza', 'Mila', 'Aïn Defla', 
    'Naâma', 'Aïn Témouchent', 'Ghardaïa', 'Relizane'
  ];
  
  bool _isLoading = true;
  List<dynamic> _farms = [];

  @override
  void initState() {
    super.initState();
    _fetchFarms();
  }

  Future<void> _fetchFarms() async {
    setState(() => _isLoading = true);
    final res = await widget.apiService.getFarms();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res['success'] == true) {
          _farms = res['farms'] ?? [];
        }
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    setState(() => _isLoading = true);

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled.')));
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _isLoading = false);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are denied')));
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are permanently denied, we cannot request permissions.')));
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _latCtrl.text = position.latitude.toString();
        _lonCtrl.text = position.longitude.toString();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to get location')));
    }
  }

  Future<void> _addFarm() async {
    final name = _nameCtrl.text.trim();
    final city = _selectedCity;
    final lat = double.tryParse(_latCtrl.text.trim());
    final lon = double.tryParse(_lonCtrl.text.trim());

    if (name.isEmpty || lat == null || lon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields with valid data")),
      );
      return;
    }

    setState(() => _isLoading = true);
    final res = await widget.apiService.addFarm(name, city, lat, lon);
    
    if (res['success'] == true) {
      _nameCtrl.clear();
      _latCtrl.clear();
      _lonCtrl.clear();
      _fetchFarms();
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['error'] ?? "Failed to add farm")),
        );
      }
    }
  }

  Future<void> _deleteFarm(int id) async {
    setState(() => _isLoading = true);
    final res = await widget.apiService.deleteFarm(id);
    if (res['success'] == true) {
      _fetchFarms();
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['error'] ?? "Failed to delete farm")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.trans['add_new_farm'] ?? "Add New Farm", style: TextStyle(color: widget.isDarkMode ? Colors.greenAccent : Colors.green, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          TextField(
            controller: _nameCtrl,
            style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
            decoration: InputDecoration(labelText: widget.trans['farm_name'] ?? "Farm Name", prefixIcon: const Icon(Icons.agriculture)),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _selectedCity,
            dropdownColor: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
            decoration: InputDecoration(labelText: widget.trans['city'] ?? "City (Wilaya)", prefixIcon: const Icon(Icons.location_city)),
            items: _algerianCities.map((c) => DropdownMenuItem(value: c, child: Text(widget.trans['city_${c.toLowerCase()}'] ?? c))).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedCity = val);
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _latCtrl,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                  decoration: InputDecoration(labelText: widget.trans['latitude'] ?? "Latitude", prefixIcon: const Icon(Icons.location_on)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _lonCtrl,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                  decoration: InputDecoration(labelText: widget.trans['longitude'] ?? "Longitude", prefixIcon: const Icon(Icons.location_on)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _getCurrentLocation,
              icon: const Icon(Icons.gps_fixed, color: Colors.blueAccent),
              label: Text(widget.trans['retry_gps'] ?? "Use GPS", style: const TextStyle(color: Colors.blueAccent)),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              minimumSize: const Size.fromHeight(50)
            ),
            onPressed: _addFarm,
            child: Text(widget.trans['save_farm'] ?? "Save Farm", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 30),
          Text(widget.trans['your_farms'] ?? "Your Farms", style: TextStyle(color: widget.isDarkMode ? Colors.greenAccent : Colors.green, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (_farms.isEmpty)
             Text(widget.trans['no_farms_found'] ?? "No farms found. Please add a farm to start recording logs.", style: const TextStyle(color: Colors.grey)),
          ..._farms.map((f) => Card(
            color: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              title: Text(f['name'], style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
              subtitle: Text("${widget.trans['city'] ?? 'City'}: ${f['city'] ?? (widget.trans['unknown'] ?? 'Unknown')} | ${widget.trans['latitude'] ?? 'Lat'}: ${f['latitude']} | ${widget.trans['longitude'] ?? 'Lon'}: ${f['longitude']}", style: const TextStyle(color: Colors.grey)),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () => _deleteFarm(f['id']),
              ),
            ),
          ))
        ],
      ),
    );
  }
}

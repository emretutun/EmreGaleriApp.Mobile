import 'dart:convert';
import 'package:emregalerimobile/services/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'car_detail_page.dart';
import 'car_edit_page.dart';
import 'admin_car_add.dart';

// Eğer ApiService'de baseUrl tanımlıysa burayı kaldırabilirsin.
// const String baseUrl = "https://520377323e0d.ngrok-free.app";

class AdminCarListPage extends StatefulWidget {
  final String token;
  const AdminCarListPage({required this.token, super.key});

  @override
  State<AdminCarListPage> createState() => _AdminCarListPageState();
}

class _AdminCarListPageState extends State<AdminCarListPage> {
  List<dynamic> _cars = [];
  List<dynamic> _filteredCars = [];
  bool _isLoading = true;
  String _selectedBrand = 'Tümü';

  List<String> _brandOptions = ['Tümü'];

  @override
  void initState() {
    super.initState();
    _fetchCars();
  }

  Future<void> _fetchCars() async {
    final uri = Uri.parse("${ApiService.baseUrl}/api/cars");
    try {
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer ${widget.token}',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _cars = data;
          _brandOptions = ['Tümü', ...{for (var car in data) car['brand']}];
          _applyFilter();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        _showError('Sunucudan hata: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Sunucuya bağlanılamadı.');
    }
  }

  void _applyFilter() {
    setState(() {
      _filteredCars = _selectedBrand == 'Tümü'
          ? _cars
          : _cars.where((car) => car['brand'] == _selectedBrand).toList();
    });
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _deleteCar(int carId) async {
    final uri = Uri.parse("${ApiService.baseUrl}/api/cars/$carId");
    try {
      final response = await http.delete(uri, headers: {
        'Authorization': 'Bearer ${widget.token}',
      });
      if (response.statusCode == 200 || response.statusCode == 204) {
        _showError('Araç silindi.');
        await _fetchCars();
      } else {
        _showError('Silme hatası: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Sunucu hatası.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Araç Listesi'),
        backgroundColor: Colors.indigo,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.indigo[50],
            child: Row(
              children: [
                const Icon(Icons.filter_alt_outlined, color: Colors.indigo),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedBrand,
                    items: _brandOptions
                        .map((brand) => DropdownMenuItem(
                              value: brand,
                              child: Text(brand),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _selectedBrand = value;
                        _applyFilter();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCars.isEmpty
                    ? const Center(child: Text("Filtreye uygun araç bulunamadı."))
                    : ListView.builder(
                        itemCount: _filteredCars.length,
                        itemBuilder: (context, index) {
                          final car = _filteredCars[index];
                          return Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => CarDetailPage(car: car)),
                                );
                              },
                              onDoubleTap: () async {
                                final updated = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        CarEditPage(car: car, token: widget.token),
                                  ),
                                );
                                if (updated == true) await _fetchCars();
                              },
                              onLongPress: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Aracı sil'),
                                    content: const Text('Bu aracı silmek istiyor musun?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: const Text('İptal'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text('Sil'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed == true) await _deleteCar(car['id']);
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    if (car['imageUrl'] != null && car['imageUrl'] != '')
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          '${ApiService.baseUrl}${car['imageUrl']}',
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Icon(Icons.image_not_supported),
                                        ),
                                      )
                                    else
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.image_not_supported, size: 40),
                                      ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text("${car['brand']} ${car['model']}",
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 4),
                                          Text("Fiyat: ${car['dailyPrice']} ₺",
                                              style: const TextStyle(color: Colors.black54)),
                                          if (car['modelYear'] != null)
                                            Text("Yıl: ${car['modelYear']}",
                                                style:
                                                    const TextStyle(color: Colors.black45)),
                                        ],
                                      ),
                                    ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final added = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AdminCarAddPage(token: widget.token)),
          );
          if (added == true) await _fetchCars();
        },
        backgroundColor: const Color.fromARGB(255, 123, 130, 247),
        child: const Icon(Icons.add),
      ),
    );
  }
}

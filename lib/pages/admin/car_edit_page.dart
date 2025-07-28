import 'dart:convert';
import 'dart:io';
import 'package:emregalerimobile/services/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';



class CarEditPage extends StatefulWidget {
  final Map<String, dynamic> car;
  final String token;

  const CarEditPage({required this.car, required this.token, super.key});

  @override
  State<CarEditPage> createState() => _CarEditPageState();
}

class _CarEditPageState extends State<CarEditPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _brandController;
  late TextEditingController _modelController;
  late TextEditingController _yearController;
  late TextEditingController _dailyPriceController;
  late TextEditingController _descriptionController;
  late TextEditingController _mileageController;

  // ignore: unused_field
  File? _selectedImageFile;
  String? _uploadedImageUrl;

  String? _selectedFuelType;
  String? _selectedColor;
  int? _selectedGearType;
  List<Map<String, dynamic>> _licenseTypes = [];
  List<int> _selectedLicenseTypeIds = [];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _brandController = TextEditingController(text: widget.car['brand'] ?? '');
    _modelController = TextEditingController(text: widget.car['model'] ?? '');
    _yearController = TextEditingController(text: widget.car['modelYear'].toString());
    _dailyPriceController = TextEditingController(text: widget.car['dailyPrice'].toString());
    _descriptionController = TextEditingController(text: widget.car['description'] ?? '');
    _mileageController = TextEditingController(text: widget.car['mileage'].toString());

    _uploadedImageUrl = widget.car['imageUrl'];
    _selectedFuelType = widget.car['fuelType'];
    _selectedColor = widget.car['color'];
    _selectedGearType = widget.car['gearType'];
    _selectedLicenseTypeIds = List<int>.from(widget.car['licenseTypes']?.map((lt) => lt['id']) ?? []);

    _fetchLicenseTypes();
  }

  Future<void> _fetchLicenseTypes() async {
    final uri = Uri.parse('${ApiService.baseUrl}/api/license-types');
    try {
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer ${widget.token}',
      });
      if (response.statusCode == 200) {
        final List decoded = jsonDecode(response.body);
        setState(() {
          _licenseTypes = decoded.cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      debugPrint("Ehliyet türleri alınamadı: $e");
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      final file = File(picked.path);
      setState(() => _selectedImageFile = file);
      await _uploadImage(file);
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    final uri = Uri.parse('${ApiService.baseUrl}/api/upload');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer ${widget.token}';
    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final resStr = await response.stream.bytesToString();
        final decoded = jsonDecode(resStr);
        setState(() {
          _uploadedImageUrl = decoded['imageUrl'];
        });
      }
    } catch (e) {
      debugPrint("Resim yüklenemedi: $e");
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resim yükleme başarısız oldu.')),
      );
    }
  }

  Future<void> _updateCar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final uri = Uri.parse('${ApiService.baseUrl}/api/cars/${widget.car['id']}');

    final body = jsonEncode({
      'brand': _brandController.text.trim(),
      'model': _modelController.text.trim(),
      'modelYear': int.tryParse(_yearController.text.trim()) ?? 0,
      'dailyPrice': double.tryParse(_dailyPriceController.text.trim()) ?? 0,
      'description': _descriptionController.text.trim(),
      'imageUrl': _uploadedImageUrl ?? '',
      'fuelType': _selectedFuelType ?? '',
      'mileage': int.tryParse(_mileageController.text.trim()) ?? 0,
      'gearType': _selectedGearType ?? 0,
      'licenseTypeIds': _selectedLicenseTypeIds,
      'color': _selectedColor ?? '',
    });

    try {
      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Araç başarıyla güncellendi.')),
        );
        // ignore: use_build_context_synchronously
        Navigator.pop(context, true);
      } else {
        final error = jsonDecode(response.body)['message'] ?? 'Bir hata oluştu';
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    } catch (e) {
      debugPrint("Araç güncelleme hatası: $e");
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sunucu hatası oluştu.')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _dailyPriceController.dispose();
    _descriptionController.dispose();
    _mileageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Araç Düzenle'),
        backgroundColor: Colors.indigo.shade700,
        elevation: 0,
      ),
      backgroundColor: Colors.grey.shade100,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(), // Klavyeyi kapatmak için
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            children: [
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (_uploadedImageUrl != null && _uploadedImageUrl!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            ApiService.baseUrl + _uploadedImageUrl!,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.broken_image, size: 150, color: Colors.grey),
                          ),
                        )
                      else
                        Container(
                          height: 180,
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade50,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Icon(Icons.directions_car, size: 80, color: Colors.grey),
                          ),
                        ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          backgroundColor: Colors.indigo.shade700,
                          foregroundColor: Colors.white, // Yazı ve ikon rengi
                        ),
                        onPressed: _pickImage,
                        icon: const Icon(Icons.image),
                        label: const Text(
                          "Resim Seç",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildTextField(_brandController, 'Marka', 'Marka zorunlu'),
                        const SizedBox(height: 16),
                        _buildTextField(_modelController, 'Model', 'Model zorunlu'),
                        const SizedBox(height: 16),
                        _buildTextField(_yearController, 'Model Yılı', null,
                            keyboardType: TextInputType.number),
                        const SizedBox(height: 16),
                        _buildTextField(_dailyPriceController, 'Günlük Fiyat', null,
                            keyboardType: TextInputType.number),
                        const SizedBox(height: 16),
                        _buildTextField(_mileageController, 'Kilometre', null,
                            keyboardType: TextInputType.number),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            labelText: 'Açıklama',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.indigo.shade50,
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          value: _selectedFuelType,
                          items: ['Benzin', 'Dizel', 'Elektrik', 'LPG']
                              .map((fuel) => DropdownMenuItem(value: fuel, child: Text(fuel)))
                              .toList(),
                          onChanged: (val) => setState(() => _selectedFuelType = val),
                          decoration: InputDecoration(
                            labelText: 'Yakıt Türü',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.indigo.shade50,
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int>(
                          value: _selectedGearType,
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('Otomatik')),
                            DropdownMenuItem(value: 2, child: Text('Yarı Otomatik')),
                            DropdownMenuItem(value: 3, child: Text('Manuel')),
                          ],
                          onChanged: (val) => setState(() => _selectedGearType = val),
                          decoration: InputDecoration(
                            labelText: 'Vites Türü',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.indigo.shade50,
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedColor,
                          items: ['Beyaz', 'Siyah', 'Kırmızı', 'Mavi', 'Gri']
                              .map((color) => DropdownMenuItem(value: color, child: Text(color)))
                              .toList(),
                          onChanged: (val) => setState(() => _selectedColor = val),
                          decoration: InputDecoration(
                            labelText: 'Renk',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.indigo.shade50,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ehliyet Türleri:',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: Colors.indigo.shade900,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                height: 3,
                                width: 120,
                                decoration: BoxDecoration(
                                  color: Colors.indigo.shade300,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Card(
                          margin: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Column(
                              children: _licenseTypes.map((lt) {
                                final id = lt['id'] as int;
                                final name = lt['name'] as String;
                                return CheckboxListTile(
                                  dense: true,
                                  activeColor: Colors.indigo.shade600,
                                  controlAffinity: ListTileControlAffinity.leading,
                                  value: _selectedLicenseTypeIds.contains(id),
                                  title: Text(name, style: const TextStyle(fontSize: 16)),
                                  onChanged: (checked) {
                                    setState(() {
                                      if (checked == true) {
                                        _selectedLicenseTypeIds.add(id);
                                      } else {
                                        _selectedLicenseTypeIds.remove(id);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              backgroundColor: Colors.indigo.shade700,
                              disabledBackgroundColor: Colors.grey.shade400,
                              elevation: 5,
                            ),
                            onPressed: _isSaving ? null : _updateCar,
                            child: _isSaving
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : const Text(
                                    'Güncelle',
                                    style: TextStyle(
                                        fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String? validatorMsg,
      {TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.indigo.shade50,
      ),
      validator: validatorMsg == null ? null : (val) => val == null || val.isEmpty ? validatorMsg : null,
    );
  }
}

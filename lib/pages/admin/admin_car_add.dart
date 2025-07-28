import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'package:emregalerimobile/services/api.dart';

class AdminCarAddPage extends StatefulWidget {
  final String token;
  const AdminCarAddPage({required this.token, super.key});

  @override
  State<AdminCarAddPage> createState() => _AdminCarAddPageState();
}

class _AdminCarAddPageState extends State<AdminCarAddPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _dailyPriceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _mileageController = TextEditingController();

  // ignore: unused_field
  File? _selectedImageFile;
  String? _uploadedImageUrl;

  String? _selectedFuelType;
  String? _selectedColor;
  int? _selectedGearType;
  List<Map<String, dynamic>> _licenseTypes = [];
  final List<int> _selectedLicenseTypeIds = [];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
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
    final picked = await picker.pickImage(source: ImageSource.gallery);
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
    }
  }

  Future<void> _saveCar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final uri = Uri.parse('${ApiService.baseUrl}/api/cars');

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
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Araç başarıyla eklendi.')),
        );
        Navigator.pop(context, true);
      } else {
        final error = jsonDecode(response.body)['message'] ?? 'Bir hata oluştu';
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    } catch (e) {
      debugPrint("Araç ekleme hatası: $e");
      if (!mounted) return;
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
    final baseTextStyle =
        TextStyle(color: Colors.indigo.shade900, fontWeight: FontWeight.w600);
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Yeni Araç Ekle'),
        centerTitle: true,
        backgroundColor: Colors.indigo.shade700,
        elevation: 2,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                if (_uploadedImageUrl != null && _uploadedImageUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      '${ApiService.baseUrl}${_uploadedImageUrl!}',
                      height: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 180,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.broken_image,
                            size: 80, color: Colors.grey),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text(
                    "Resim Seç",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                _buildTextField(_brandController, 'Marka', 'Marka zorunlu'),
                const SizedBox(height: 12),
                _buildTextField(_modelController, 'Model', 'Model zorunlu'),
                const SizedBox(height: 12),
                _buildTextField(_yearController, 'Model Yılı', 'Model yılı zorunlu',
                    keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                _buildTextField(_dailyPriceController, 'Günlük Fiyat',
                    'Günlük fiyat zorunlu',
                    keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                _buildTextField(_mileageController, 'Kilometre', 'Kilometre zorunlu',
                    keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Açıklama',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.indigo.shade50,
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedFuelType,
                  items: ['Benzin', 'Dizel', 'Elektrik', 'LPG']
                      .map((fuel) =>
                          DropdownMenuItem(value: fuel, child: Text(fuel)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedFuelType = val),
                  decoration: InputDecoration(
                    labelText: 'Yakıt Türü',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.indigo.shade50,
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Yakıt türü zorunlu' : null,
                ),
                const SizedBox(height: 12),
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
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.indigo.shade50,
                  ),
                  validator: (val) =>
                      val == null ? 'Vites türü zorunlu' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedColor,
                  items: ['Beyaz', 'Siyah', 'Kırmızı', 'Mavi', 'Gri']
                      .map((color) =>
                          DropdownMenuItem(value: color, child: Text(color)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedColor = val),
                  decoration: InputDecoration(
                    labelText: 'Renk',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.indigo.shade50,
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Renk zorunlu' : null,
                ),
                const SizedBox(height: 16),
                Text('Ehliyet Türleri:',
                    style: baseTextStyle.copyWith(fontSize: 16)),
                ..._licenseTypes.map((lt) {
                  final id = lt['id'] as int;
                  final name = lt['name'] as String;
                  return CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _selectedLicenseTypeIds.contains(id),
                    title: Text(name,
                        style: baseTextStyle.copyWith(fontSize: 15)),
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
                // ignore: unnecessary_to_list_in_spreads
                }).toList(),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    onPressed: _isSaving ? null : _saveCar,
                    child: _isSaving
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 3),
                          )
                        : const Text('Kaydet'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      String? validatorMsg,
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
      validator:
          validatorMsg == null ? null : (val) => val == null || val.isEmpty ? validatorMsg : null,
    );
  }
}

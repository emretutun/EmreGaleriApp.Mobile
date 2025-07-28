// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';

import 'package:emregalerimobile/services/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class UserEditProfilePage extends StatefulWidget {
  final String token;

  const UserEditProfilePage({required this.token, super.key});

  @override
  State<UserEditProfilePage> createState() => _UserEditProfilePageState();
}

class _UserEditProfilePageState extends State<UserEditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nationalIdController = TextEditingController();
  final TextEditingController _drivingExperienceController = TextEditingController();

  DateTime? _birthDate;
  String? _selectedGender;

  // ignore: unused_field
  File? _selectedImageFile;
  String? _uploadedImageUrl;

  bool _isLoading = false;

  List<Map<String, dynamic>> _allLicenseTypes = [];
  Set<int> _selectedLicenseTypeIds = {};

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    setState(() => _isLoading = true);

    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/api/UserProfileApi/edit-data'),
      headers: {'Authorization': 'Bearer ${widget.token}', 'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final profile = data['profile'];
      final allLicenses = List<Map<String, dynamic>>.from(data['allLicenseTypes']);

      setState(() {
        _userNameController.text = profile['userName'] ?? '';
        _emailController.text = profile['email'] ?? '';
        _nationalIdController.text = profile['nationalId'] ?? '';
        _drivingExperienceController.text =
            (profile['drivingExperienceYears']?.toString()) ?? '';
        _uploadedImageUrl = profile['pictureUrl'];
        _selectedGender = (profile['gender'] as String?)?.toLowerCase();
        _birthDate = profile['birthDate'] != null
            ? DateTime.tryParse(profile['birthDate'])
            : null;

        _allLicenseTypes = allLicenses;
        _selectedLicenseTypeIds = {
          for (var l in profile['licenseTypes']) l['id'] as int
        };
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profil yüklenemedi: ${response.statusCode}')),
      );
    }

    setState(() => _isLoading = false);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final file = File(picked.path);
      setState(() {
        _selectedImageFile = file;
      });
      await _uploadImage(file);
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    final uri = Uri.parse('${ApiService.baseUrl}/api/UserProfileApi/upload-image');
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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resim yüklenirken hata oluştu')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Resim yüklenemedi: $e')),
      );
    }
  }

  Future<void> _selectBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(1990, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final body = jsonEncode({
      'userName': _userNameController.text.trim(),
      'email': _emailController.text.trim(),
      'nationalId': _nationalIdController.text.trim().isEmpty
          ? null
          : _nationalIdController.text.trim(),
      'gender': _selectedGender,
      'birthDate': _birthDate?.toIso8601String(),
      'drivingExperienceYears':
          int.tryParse(_drivingExperienceController.text.trim()),
      'pictureUrl': _uploadedImageUrl,
      'licenseTypeIds': _selectedLicenseTypeIds.toList(), // 👈 yeni alan
    });

    final response = await http.put(
      Uri.parse('${ApiService.baseUrl}/api/UserProfileApi'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: body,
    );

    setState(() => _isLoading = false);

    if (response.statusCode == 204) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil güncellendi')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Güncelleme başarısız: ${response.statusCode}')),
      );
    }
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _emailController.dispose();
    _nationalIdController.dispose();
    _drivingExperienceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilimi Düzenle'),
        backgroundColor: Colors.indigo.shade700,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (_uploadedImageUrl != null && _uploadedImageUrl!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: Image.network(
                          ApiService.baseUrl + _uploadedImageUrl!,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.person, size: 100),
                        ),
                      ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image),
                      label: const Text('Fotoğraf Seç'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 198, 206, 255),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _userNameController,
                      decoration: const InputDecoration(labelText: 'Kullanıcı Adı'),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Kullanıcı adı zorunlu' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Email zorunlu';
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(val)) return 'Geçerli email giriniz';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nationalIdController,
                      decoration: const InputDecoration(labelText: 'TC Kimlik No'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Cinsiyet'),
                      value: _selectedGender,
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Belirtilmemiş')),
                        DropdownMenuItem(value: 'male', child: Text('Erkek')),
                        DropdownMenuItem(value: 'female', child: Text('Kadın')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: _selectBirthDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Doğum Tarihi'),
                        child: Text(
                          _birthDate != null
                              ? '${_birthDate!.day}.${_birthDate!.month}.${_birthDate!.year}'
                              : 'Seçiniz',
                          style: TextStyle(
                              color: _birthDate == null ? Colors.grey.shade600 : Colors.black),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _drivingExperienceController,
                      decoration: const InputDecoration(labelText: 'Sürüş Deneyimi (Yıl)'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Ehliyet Türleri", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Column(
                      children: _allLicenseTypes.map((license) {
                        final id = license['id'] as int;
                        final name = license['name'];
                        final isSelected = _selectedLicenseTypeIds.contains(id);

                        return CheckboxListTile(
                          title: Text(name),
                          value: isSelected,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedLicenseTypeIds.add(id);
                              } else {
                                _selectedLicenseTypeIds.remove(id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade700,
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
                      ),
                      child: const Text('Güncelle', style: TextStyle(fontSize: 18)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

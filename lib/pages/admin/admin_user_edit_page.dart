import 'dart:io';
import 'package:emregalerimobile/services/api.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';



class AdminUserEditPage extends StatefulWidget {
  final Map user;

  const AdminUserEditPage({super.key, required this.user});

  @override
  State<AdminUserEditPage> createState() => _AdminUserEditPageState();
}

class _AdminUserEditPageState extends State<AdminUserEditPage> {
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  String gender = '-';
  int experience = 0;

  File? selectedImageFile;
  final ImagePicker _picker = ImagePicker();

  bool isUploading = false;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.user['name'] ?? '');
    emailController = TextEditingController(text: widget.user['email'] ?? '');
    phoneController = TextEditingController(text: widget.user['phone'] ?? '');

    String g = (widget.user['gender'] ?? '').toString().toLowerCase();
    if (g == 'male') {
      gender = 'Erkek';
    } else if (g == 'female') {
      gender = 'Kadın';
    } else {
      gender = '-';
    }

    experience = widget.user['experience'] ?? 0;
  }

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        selectedImageFile = File(picked.path);
      });
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');

    final uri = Uri.parse('${ApiService.baseUrl}/api/UserApi/UploadProfilePicture');
    var request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final data = jsonDecode(respStr);
        return data['fileName'];
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Fotoğraf yükleme hatası: ${response.statusCode}")),
        );
        return null;
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Fotoğraf yüklenirken hata: $e")),
      );
      return null;
    }
  }

  Future<void> _saveChanges() async {
    setState(() {
      isUploading = true;
    });

    String? uploadedFileName;
    if (selectedImageFile != null) {
      uploadedFileName = await _uploadImage(selectedImageFile!);
      if (uploadedFileName == null) {
        setState(() {
          isUploading = false;
        });
        return;
      }
    }

    final updatedData = {
      'Name': nameController.text,
      'Email': emailController.text,
      'Phone': phoneController.text,
      'Gender': gender == 'Erkek' ? 'Male' : (gender == 'Kadın' ? 'Female' : null),
      'Experience': experience,
    };

    if (uploadedFileName != null) {
      updatedData['Picture'] = uploadedFileName;
    }

    // ignore: use_build_context_synchronously
    Navigator.pop(context, updatedData);

    setState(() {
      isUploading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kullanıcı Düzenle'),
        backgroundColor: Colors.indigo.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: selectedImageFile != null
                      ? FileImage(selectedImageFile!)
                      : (widget.user['picture'] != null
                          ? NetworkImage('${ApiService.baseUrl}/userpictures/${widget.user['picture']}')
                          : null) as ImageProvider<Object>?,
                  child: selectedImageFile == null && widget.user['picture'] == null
                      ? const Icon(Icons.person, size: 60, color: Colors.grey)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 4,
                  child: InkWell(
                    onTap: _pickImage,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.indigo,
                        shape: BoxShape.circle,
                        border: Border.all(width: 2, color: Colors.white),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 24),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Ad Soyad'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Telefon'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: gender,
              decoration: const InputDecoration(labelText: 'Cinsiyet'),
              items: const [
                DropdownMenuItem(value: 'Erkek', child: Text('Erkek')),
                DropdownMenuItem(value: 'Kadın', child: Text('Kadın')),
                DropdownMenuItem(value: '-', child: Text('-')),
              ],
              onChanged: (value) {
                setState(() {
                  gender = value ?? '-';
                });
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              initialValue: experience.toString(),
              decoration: const InputDecoration(labelText: 'Sürüş Deneyimi (yıl)'),
              keyboardType: TextInputType.number,
              onChanged: (val) {
                setState(() {
                  experience = int.tryParse(val) ?? 0;
                });
              },
            ),
            const SizedBox(height: 30),
            isUploading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _saveChanges,
                    child: const Text('Kaydet'),
                  ),
          ],
        ),
      ),
    );
  }
}

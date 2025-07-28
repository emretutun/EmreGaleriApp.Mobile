import 'dart:convert';
import 'package:emregalerimobile/pages/admin/admin_user_edit_page.dart';
import 'package:emregalerimobile/pages/admin/admin_user_assign_role_page.dart';
import 'package:emregalerimobile/services/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';



class AdminUserListPage extends StatefulWidget {
  const AdminUserListPage({super.key});

  @override
  State<AdminUserListPage> createState() => _AdminUserListPageState();
}

class _AdminUserListPageState extends State<AdminUserListPage> {
  List users = [];
  List filteredUsers = [];
  bool isLoading = true;
  String? token;
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('jwt_token');

    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/api/UserApi'),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      setState(() {
        users = json.decode(response.body);
        filteredUsers = users;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Sunucu hatası: ${response.statusCode}")),
      );
    }
  }

  void _filterUsers(String query) {
    query = query.toLowerCase();
    setState(() {
      searchQuery = query;
      filteredUsers = users.where((user) {
        final name = (user['name'] ?? '').toString().toLowerCase();
        final email = (user['email'] ?? '').toString().toLowerCase();
        return name.contains(query) || email.contains(query);
      }).toList();
    });
  }

  Future<void> _deleteUser(String userId) async {
    final uri = Uri.parse("${ApiService.baseUrl}/api/UserApi/$userId");
    try {
      final response = await http.delete(uri, headers: {
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 204 || response.statusCode == 200) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Kullanıcı silindi.")),
        );
        await fetchUsers();
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Silme hatası: ${response.statusCode}")),
        );
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sunucu hatası.")),
      );
    }
  }

  Future<void> _updateUser(String userId, Map<String, dynamic> updateData) async {
    final uri = Uri.parse("${ApiService.baseUrl}/api/UserApi/$userId");
    try {
      final response = await http.put(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(updateData),
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Kullanıcı güncellendi.")),
        );
        await fetchUsers();
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Güncelleme hatası: ${response.statusCode}")),
        );
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sunucu hatası.")),
      );
    }
  }

  // ignore: unused_element
  Future<void> _showUpdateDialog(Map user) async {
    final nameController = TextEditingController(text: user['name']);
    final emailController = TextEditingController(text: user['email']);
    final phoneController = TextEditingController(text: user['phone'] ?? '');
    String gender = user['gender']?.toString().toLowerCase() ?? '';
    int experience = user['experience'] ?? 0;

    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Kullanıcı Güncelle'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Ad Soyad'),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Telefon'),
                ),
                DropdownButtonFormField<String>(
                  value: gender.isNotEmpty ? (gender == 'male' ? 'Erkek' : 'Kadın') : null,
                  decoration: const InputDecoration(labelText: 'Cinsiyet'),
                  items: const [
                    DropdownMenuItem(value: 'Erkek', child: Text('Erkek')),
                    DropdownMenuItem(value: 'Kadın', child: Text('Kadın')),
                    DropdownMenuItem(value: '-', child: Text('-')),
                  ],
                  onChanged: (value) {
                    gender = value ?? '-';
                  },
                ),
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Sürüş Deneyimi (yıl)'),
                  controller: TextEditingController(text: experience.toString()),
                  onChanged: (val) {
                    experience = int.tryParse(val) ?? 0;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('İptal'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text('Güncelle'),
              onPressed: () {
                Map<String, dynamic> updateData = {
                  'Name': nameController.text,
                  'Email': emailController.text,
                  'Phone': phoneController.text,
                  'Gender': gender == '-' ? null : (gender == 'Erkek' ? 'Male' : 'Female'),
                  'Experience': experience,
                };
                _updateUser(user['id'], updateData);
                Navigator.pop(context);
              },
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kullanıcı Listesi"),
        backgroundColor: Colors.indigo.shade700,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Kullanıcı ara...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _filterUsers,
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredUsers.isEmpty
                    ? const Center(child: Text("Kullanıcı bulunamadı."))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          return _buildUserCard(user);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map user) {
    final roles = (user['roles'] as List).join(', ');
    final licenseTypes = (user['licenseTypes'] as List).join(', ');

    String gender = user['gender']?.toString().toLowerCase() ?? "-";
    // ignore: curly_braces_in_flow_control_structures
    if (gender == 'male') gender = 'Erkek';
    // ignore: curly_braces_in_flow_control_structures
    else if (gender == 'female') gender = 'Kadın';
    // ignore: curly_braces_in_flow_control_structures
    else gender = '-';

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      shadowColor: Colors.indigo.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: user['picture'] != null && user['picture'].toString().isNotEmpty
                  ? Image.network(
                      "${ApiService.baseUrl}/userpictures/${user['picture']}",
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: const Icon(Icons.person, size: 40, color: Colors.grey),
                      ),
                    )
                  : Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: const Icon(Icons.person, size: 40, color: Colors.grey),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user['name'] ?? '-',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(user['email'] ?? '-', style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 16, color: Colors.indigo),
                      const SizedBox(width: 6),
                      Text(user['phone'] ?? '-'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text("Cinsiyet: $gender"),
                  const SizedBox(height: 6),
                  Text("Sürüş Deneyimi: ${user['experience'] ?? 0} yıl"),
                  const SizedBox(height: 6),
                  Text("Ehliyetler: $licenseTypes"),
                  const SizedBox(height: 6),
                  Text("Roller: $roles"),
                ],
              ),
            ),
            // Butonlar
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  tooltip: "Düzenle",
                  onPressed: () async {
                    final updatedData = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminUserEditPage(user: user),
                      ),
                    );

                    if (updatedData != null) {
                      await _updateUser(user['id'], updatedData);
                      await fetchUsers();
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.security, color: Colors.orange),
                  tooltip: "Rol Ata",
                  onPressed: () async {
                    final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminUserAssignRolePage(
                          userId: user['id'],
                          currentRoles: List<String>.from(user['roles']),
                        ),
                      ),
                    );

                    if (updated == true) {
                      await fetchUsers();
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: "Sil",
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Kullanıcıyı sil'),
                        content: const Text('Bu kullanıcıyı silmek istediğinize emin misiniz?'),
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

                    if (confirmed == true) {
                      await _deleteUser(user['id']);
                      await fetchUsers();
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:emregalerimobile/services/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AdminRoleListPage extends StatefulWidget {
  const AdminRoleListPage({super.key});

  @override
  State<AdminRoleListPage> createState() => _AdminRoleListPageState();
}

class _AdminRoleListPageState extends State<AdminRoleListPage> {
  List roles = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRoles();
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("jwt_token") ?? "";
  }

  Future<void> fetchRoles() async {
    final token = await _getToken();
    final url = Uri.parse('${ApiService.baseUrl}/api/RoleApi');

    final response = await http.get(url, headers: {
      "Authorization": "Bearer $token",
    });

    if (response.statusCode == 200) {
      setState(() {
        roles = json.decode(response.body);
        isLoading = false;
      });
    } else {
      debugPrint("Hata: ${response.statusCode}");
    }
  }

  Future<void> deleteRole(String id) async {
    final token = await _getToken();
    final url = Uri.parse('${ApiService.baseUrl}/api/RoleApi/$id');

    final response = await http.delete(url, headers: {
      "Authorization": "Bearer $token",
    });

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Rol silindi.")),
      );
      fetchRoles();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Silme başarısız! (${response.statusCode})")),
      );
    }
  }

  Future<void> showRoleDialog({String? id, String? currentName}) async {
    // ignore: no_leading_underscores_for_local_identifiers
    final _controller = TextEditingController(text: currentName ?? "");

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(id == null ? "Yeni Rol Ekle" : "Rolü Güncelle"),
          content: TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: "Rol Adı",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("İptal"),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text("Kaydet"),
              onPressed: () async {
                final name = _controller.text.trim();
                if (name.isEmpty) return;

                final token = await _getToken();
                final headers = {
                  "Authorization": "Bearer $token",
                  "Content-Type": "application/json",
                };

                final body = jsonEncode({"name": name});

                http.Response response;

                if (id == null) {
                  final url = Uri.parse('${ApiService.baseUrl}/api/RoleApi');
                  response = await http.post(url, headers: headers, body: body);
                } else {
                  final url = Uri.parse('${ApiService.baseUrl}/api/RoleApi/$id');
                  response = await http.put(url, headers: headers, body: body);
                }

                if (response.statusCode == 200) {
                  Navigator.pop(context);
                  fetchRoles();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(id == null ? "Rol eklendi." : "Rol güncellendi.")),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("İşlem başarısız! (${response.statusCode})")),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Rol Yönetimi"),
        backgroundColor: Colors.indigo.shade700,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: ListView.builder(
                itemCount: roles.length,
                itemBuilder: (context, index) {
                  final role = roles[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.indigo,
                        child: Icon(Icons.security, color: Colors.white),
                      ),
                      title: Text(role["name"], style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            showRoleDialog(id: role["id"], currentName: role["name"]);
                          } else if (value == 'delete') {
                            deleteRole(role["id"]);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                          const PopupMenuItem(value: 'delete', child: Text('Sil')),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showRoleDialog();
        },
        backgroundColor: const Color.fromARGB(255, 158, 171, 243),
        icon: const Icon(Icons.add),
        label: const Text("Yeni Rol"),
      ),
    );
  }
}

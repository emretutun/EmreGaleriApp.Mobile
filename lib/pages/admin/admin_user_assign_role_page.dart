// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:emregalerimobile/services/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';



class AdminUserAssignRolePage extends StatefulWidget {
  final String userId;
  final List<String> currentRoles;

  const AdminUserAssignRolePage({
    super.key,
    required this.userId,
    required this.currentRoles,
  });

  @override
  State<AdminUserAssignRolePage> createState() => _AdminUserAssignRolePageState();
}

class _AdminUserAssignRolePageState extends State<AdminUserAssignRolePage> {
  List<Map<String, dynamic>> allRoles = []; // id ve name birlikte
  Set<String> selectedRoleNames = {};
  bool isLoading = true;
  String? token;

  @override
  void initState() {
    super.initState();
    // Kullanıcının mevcut rollerinin isimlerini set olarak sakla
    selectedRoleNames = widget.currentRoles.toSet();
    _loadTokenAndFetchRoles();
  }

  Future<void> _loadTokenAndFetchRoles() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('jwt_token');
    await _fetchAllRoles();
  }

  Future<void> _fetchAllRoles() async {
    final uri = Uri.parse('${ApiService.baseUrl}/api/RoleApi'); // Backend'deki roller endpoint
    try {
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> rolesJson = json.decode(response.body);

        // rolesJson = [ {id:..., name:...}, {id:..., name:...}, ... ]
        setState(() {
          allRoles = rolesJson.cast<Map<String, dynamic>>();
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rol listesi alınamadı: ${response.statusCode}')),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sunucu hatası: $e')),
      );
    }
  }

  Future<void> _saveRoles() async {
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kullanıcı doğrulanmadı.')),
      );
      return;
    }

    // Sadece seçilen rollerin isimlerini backend'e gönderiyoruz
    final List<String> rolesToSend = selectedRoleNames.toList();

    final uri = Uri.parse('${ApiService.baseUrl}/api/UserApi/${widget.userId}/AssignRoles');
    try {
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'roles': rolesToSend}),
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Roller başarıyla güncellendi.')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rol güncelleme hatası: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sunucu hatası: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kullanıcıya Rol Ata'),
        backgroundColor: const Color.fromARGB(255, 131, 146, 248),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Kaydet',
            onPressed: isLoading ? null : _saveRoles,
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : allRoles.isEmpty
              ? const Center(child: Text('Rol bulunamadı.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: allRoles.length,
                  itemBuilder: (context, index) {
                    final role = allRoles[index];
                    final roleName = role['name']?.toString() ?? '';
                    final isSelected = selectedRoleNames.contains(roleName);

                    return CheckboxListTile(
                      title: Text(roleName),
                      value: isSelected,
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            selectedRoleNames.add(roleName);
                          } else {
                            selectedRoleNames.remove(roleName);
                          }
                        });
                      },
                    );
                  },
                ),
    );
  }
}

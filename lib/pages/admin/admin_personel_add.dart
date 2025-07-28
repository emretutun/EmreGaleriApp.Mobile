// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:emregalerimobile/services/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Sabit baseUrl tanımı


class AdminPersonelAddPage extends StatefulWidget {
  const AdminPersonelAddPage({super.key});

  @override
  State<AdminPersonelAddPage> createState() => _AdminPersonelAddPageState();
}

class _AdminPersonelAddPageState extends State<AdminPersonelAddPage> {
  List<dynamic> users = [];
  bool isLoadingUsers = true;

  String? selectedUserId;
  final TextEditingController positionController = TextEditingController();
  final TextEditingController salaryController = TextEditingController();
  DateTime? selectedStartDate;

  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    setState(() => isLoadingUsers = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/api/userapi/yetkili'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          users = jsonDecode(response.body);
          isLoadingUsers = false;
        });
      } else {
        setState(() => isLoadingUsers = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kullanıcılar yüklenemedi: ${response.statusCode}')),
        );
      }
    } catch (e) {
      setState(() => isLoadingUsers = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata oluştu: $e')),
      );
    }
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => selectedStartDate = picked);
    }
  }

  Future<void> _savePersonel() async {
    if (selectedUserId == null ||
        positionController.text.isEmpty ||
        salaryController.text.isEmpty ||
        double.tryParse(salaryController.text) == null ||
        selectedStartDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen tüm alanları doldurun")),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';

      final body = jsonEncode({
        "userId": selectedUserId,
        "position": positionController.text,
        "salary": double.parse(salaryController.text),
        "startDate": selectedStartDate!.toIso8601String(),
      });

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/personelapi'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Personel başarıyla eklendi"), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop(true);
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: ${data.toString()}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata oluştu: $e")),
      );
    } finally {
      setState(() => isSaving = false);
    }
  }

  @override
  void dispose() {
    positionController.dispose();
    salaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Yeni Personel Ekle"),
        backgroundColor: Colors.indigo.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isLoadingUsers
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: "Kullanıcı Seç",
                            border: OutlineInputBorder(),
                          ),
                          isExpanded: true,
                          items: users
                              .map((u) => DropdownMenuItem<String>(
                                    value: u['id'],
                                    child: Text(
                                      "${u['name']} (${u['email']})",
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ))
                              .toList(),
                          onChanged: (val) => setState(() => selectedUserId = val),
                          value: selectedUserId,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: positionController,
                          decoration: const InputDecoration(
                            labelText: "Pozisyon",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: salaryController,
                          decoration: const InputDecoration(
                            labelText: "Maaş",
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _selectStartDate,
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            selectedStartDate == null
                                ? "Başlangıç Tarihi Seç"
                                : "Başlangıç: ${selectedStartDate!.day.toString().padLeft(2, '0')}.${selectedStartDate!.month.toString().padLeft(2, '0')}.${selectedStartDate!.year}",
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo.shade600,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: isSaving ? null : _savePersonel,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo.shade700,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: isSaving
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text("Kaydet", style: TextStyle(fontSize: 18)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

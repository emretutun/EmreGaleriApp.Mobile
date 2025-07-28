// ignore_for_file: use_super_parameters, use_build_context_synchronously, sort_child_properties_last

import 'package:emregalerimobile/services/api.dart';
import 'package:flutter/material.dart';
import '../../../models/personel_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Sabit base URL


class PersonelEditPage extends StatefulWidget {
  final PersonelModel personel;

  const PersonelEditPage({Key? key, required this.personel}) : super(key: key);

  @override
  State<PersonelEditPage> createState() => _PersonelEditPageState();
}

class _PersonelEditPageState extends State<PersonelEditPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _positionController;
  late TextEditingController _salaryController;
  late DateTime _startDate;

  @override
  void initState() {
    super.initState();
    _positionController = TextEditingController(text: widget.personel.position);
    _salaryController = TextEditingController(text: widget.personel.salary.toString());
    _startDate = widget.personel.startDate;
  }

  @override
  void dispose() {
    _positionController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';

    final updatedData = {
      "id": widget.personel.id,
      "userId": widget.personel.userId,
      "position": _positionController.text,
      "salary": double.tryParse(_salaryController.text) ?? 0,
      "startDate": _startDate.toIso8601String(),
    };

    final response = await http.put(
      Uri.parse('${ApiService.baseUrl}/api/personelapi/${widget.personel.id}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(updatedData),
    );

    if (response.statusCode == 200) {
      Navigator.of(context).pop(true); // Başarılı olursa true döndür, liste yenilensin
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Güncelleme başarısız: ${response.statusCode}")),
      );
    }
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Personel Düzenle"),
        backgroundColor: Colors.indigo.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _positionController,
                decoration: const InputDecoration(labelText: 'Pozisyon'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Pozisyon boş olamaz';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _salaryController,
                decoration: const InputDecoration(labelText: 'Maaş'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Maaş boş olamaz';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Geçerli bir sayı giriniz';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text("Başlangıç Tarihi: ${_startDate.day}.${_startDate.month}.${_startDate.year}"),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: _pickStartDate,
                    child: const Text("Tarih Seç"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo.shade700),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Güncelle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:emregalerimobile/services/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Reminder {
  final int id;
  final String title;
  final String? description;
  final DateTime reminderDate;
  final bool isCompleted;

  Reminder({
    required this.id,
    required this.title,
    this.description,
    required this.reminderDate,
    required this.isCompleted,
  });

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      reminderDate: DateTime.parse(json['reminderDate']),
      isCompleted: json['isCompleted'],
    );
  }
}

class AdminReminderPage extends StatefulWidget {
  final String token;

  // ignore: use_super_parameters
  const AdminReminderPage({Key? key, required this.token}) : super(key: key);

  @override
  State<AdminReminderPage> createState() => _AdminReminderPageState();
}

class _AdminReminderPageState extends State<AdminReminderPage> {
  List<Reminder> reminders = [];
  bool isLoading = false;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _fetchReminders();
  }

  Future<void> _fetchReminders() async {
    setState(() => isLoading = true);

    final url = Uri.parse('${ApiService.baseUrl}/api/reminder');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        reminders = data.map((json) => Reminder.fromJson(json)).toList();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hatırlatmalar yüklenemedi')),
      );
    }

    setState(() => isLoading = false);
  }

  Future<void> _addReminder() async {
    if (_titleController.text.trim().isEmpty || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Başlık ve tarih zorunludur')),
      );
      return;
    }

    final url = Uri.parse('${ApiService.baseUrl}/api/reminder');
    final body = jsonEncode({
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'reminderDate': _selectedDate!.toIso8601String(),
      'isCompleted': false,
    });

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode == 200) {
      _titleController.clear();
      _descriptionController.clear();
      _selectedDate = null;
      await _fetchReminders();
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hatırlatma eklenemedi')),
      );
    }
  }

  Future<void> _toggleReminder(int id) async {
    final url = Uri.parse('${ApiService.baseUrl}/api/reminder/toggle/$id');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      await _fetchReminders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Durum değiştirilemedi')),
      );
    }
  }

  Future<void> _deleteReminder(int id) async {
    final url = Uri.parse('${ApiService.baseUrl}/api/reminder/$id');

    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      await _fetchReminders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silme işlemi başarısız')),
      );
    }
  }

  void _showAddReminderDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Yeni Hatırlatma Ekle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Başlık',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Açıklama',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(_selectedDate == null
                        ? 'Tarih seçilmedi'
                        : 'Tarih: ${_selectedDate!.toLocal().toString().split(' ')[0]}'),
                    const Spacer(),
                    TextButton(
                      child: const Text('Tarih Seç'),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => _selectedDate = picked);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _titleController.clear();
                _descriptionController.clear();
                _selectedDate = null;
                Navigator.of(context).pop();
              },
              child: const Text('İptal'),
            ),
            ElevatedButton.icon(
              onPressed: _addReminder,
              icon: const Icon(Icons.save),
              label: const Text('Kaydet'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReminderList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (reminders.isEmpty) {
      return const Center(child: Text('Henüz hatırlatma yok'));
    } else {
      return ListView.builder(
        itemCount: reminders.length,
        itemBuilder: (context, index) {
          final reminder = reminders[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            color: reminder.isCompleted ? Colors.green[50] : null,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              title: Text(
                reminder.title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  decoration: reminder.isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (reminder.description != null && reminder.description!.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.notes, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(child: Text(reminder.description!)),
                      ],
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(reminder.reminderDate.toLocal().toString().split(' ')[0]),
                    ],
                  ),
                ],
              ),
              trailing: Wrap(
                spacing: 8,
                children: [
                  IconButton(
                    icon: Icon(
                      reminder.isCompleted
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      color: reminder.isCompleted ? Colors.green : null,
                    ),
                    onPressed: () => _toggleReminder(reminder.id),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteReminder(reminder.id),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hatırlatmalar'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchReminders,
          ),
        ],
      ),
      body: _buildReminderList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddReminderDialog,
        icon: const Icon(Icons.add),
        label: const Text("Hatırlatma Ekle"),
        backgroundColor: const Color.fromARGB(255, 191, 200, 252),
      ),
    );
  }
}

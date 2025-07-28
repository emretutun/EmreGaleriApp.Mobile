import 'dart:convert';
import 'package:emregalerimobile/pages/admin/admin_personel_add.dart';
import 'package:emregalerimobile/pages/admin/admin_personel_edit.dart';
import 'package:emregalerimobile/services/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../models/personel_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Sabit URL


class AdminPersonelPage extends StatefulWidget {
  const AdminPersonelPage({super.key});

  @override
  State<AdminPersonelPage> createState() => _AdminPersonelPageState();
}

class _AdminPersonelPageState extends State<AdminPersonelPage> {
  List<PersonelModel> personelList = [];
  bool isLoading = true;
  int? payingPersonelId;

  @override
  void initState() {
    super.initState();
    fetchPersoneller();
  }

  Future<void> fetchPersoneller() async {
    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/api/personelapi'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        setState(() {
          personelList = jsonList.map((json) => PersonelModel.fromJson(json)).toList();
          isLoading = false;
        });
      } else {
        _showSnackBar("Personel verileri alınamadı: ${response.statusCode}", isError: true);
        setState(() => isLoading = false);
      }
    } catch (e) {
      _showSnackBar("Bir hata oluştu: $e", isError: true);
      setState(() => isLoading = false);
    }
  }

  Future<void> _paySalary(int personelId) async {
    setState(() {
      payingPersonelId = personelId;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';

      final url = Uri.parse('${ApiService.baseUrl}/api/personelapi/$personelId/pay?monthCount=1');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _showSnackBar("${data['message']} (Ödeyen: ${data['paidBy'] ?? 'Bilinmeyen'})");
      } else {
        _showSnackBar('Maaş ödemede hata: ${response.statusCode}', isError: true);
      }
    } catch (e) {
      _showSnackBar("Bir hata oluştu: $e", isError: true);
    } finally {
      setState(() {
        payingPersonelId = null;
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _deletePersonel(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';

    final response = await http.delete(
      Uri.parse('${ApiService.baseUrl}/api/personelapi/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 204) {
      _showSnackBar("Personel başarıyla silindi.");
      fetchPersoneller();
    } else {
      _showSnackBar("Silme işlemi başarısız: ${response.statusCode}", isError: true);
    }
  }

  void _showDeleteConfirmation(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Onay"),
        content: const Text("Personeli silmek istediğinize emin misiniz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("İptal"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _deletePersonel(id);
            },
            child: const Text("Sil", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _navigateToAddPersonel() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AdminPersonelAddPage(),
      ),
    ).then((value) {
      if (value == true) {
        fetchPersoneller(); // Ekleme sonrası listeyi yenile
      }
    });
  }

  void _navigateToEditPersonel(PersonelModel personel) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PersonelEditPage(personel: personel),
      ),
    ).then((value) {
      if (value == true) {
        fetchPersoneller(); // Düzenlemeden sonra listeyi yenile
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Personel Listesi"),
        backgroundColor: Colors.indigo.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: "Yeni Personel Ekle",
            color: Colors.black,
            onPressed: _navigateToAddPersonel,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchPersoneller,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: personelList.length,
                itemBuilder: (context, index) {
                  final personel = personelList[index];
                  final isPayingThis = payingPersonelId == personel.id;

                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            personel.userName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text("E-posta: ${personel.email}", style: const TextStyle(fontSize: 15)),
                          Text("Telefon: ${personel.phoneNumber}", style: const TextStyle(fontSize: 15)),
                          const SizedBox(height: 6),
                          Text("Görev: ${personel.position}", style: const TextStyle(fontSize: 16)),
                          Text("Maaş: ${personel.salary.toStringAsFixed(2)} ₺", style: const TextStyle(fontSize: 16)),
                          Text(
                            "Başlama: ${personel.startDate.day}.${personel.startDate.month}.${personel.startDate.year}",
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: isPayingThis ? null : () => _paySalary(personel.id),
                                  icon: isPayingThis
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.payment),
                                  label: isPayingThis ? const Text("Ödeniyor...") : const Text("Maaş Öde"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(183, 245, 195, 31),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    textStyle: const TextStyle(fontSize: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                tooltip: "Düzenle",
                                onPressed: () => _navigateToEditPersonel(personel),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                tooltip: "Sil",
                                onPressed: () => _showDeleteConfirmation(personel.id),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

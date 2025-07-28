// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:emregalerimobile/services/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UserCarDetailPage extends StatefulWidget {
  final String token;
  final int carId;

  const UserCarDetailPage({super.key, required this.token, required this.carId});

  @override
  State<UserCarDetailPage> createState() => _UserCarDetailPageState();
}

class _UserCarDetailPageState extends State<UserCarDetailPage> {
  Map<String, dynamic>? carDetail;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCarDetails();
  }

  Future<void> fetchCarDetails() async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/api/usercars/${widget.carId}'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        carDetail = jsonDecode(response.body);
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Araç detayları getirilemedi: ${response.statusCode}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseUrl = ApiService.baseUrl.endsWith('/')
        ? ApiService.baseUrl.substring(0, ApiService.baseUrl.length - 1)
        : ApiService.baseUrl;

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 86, 159, 243),
          title: const Text('Araç Detayı'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (carDetail == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 86, 159, 243),
          title: const Text('Araç Detayı'),
        ),
        body: const Center(child: Text('Detaylar bulunamadı')),
      );
    }

    final imageUrl = carDetail!['imageUrl'] != null ? '$baseUrl${carDetail!['imageUrl']}' : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 86, 159, 243),
        title: Text('${carDetail!['brand']} ${carDetail!['model']}'),
        centerTitle: true,
        elevation: 3,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          height: 220,
                          color: Colors.grey.shade200,
                          child: const Center(child: CircularProgressIndicator()),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 220,
                          color: Colors.grey.shade200,
                          child: const Center(
                              child: Icon(Icons.broken_image, size: 60, color: Colors.grey)),
                        );
                      },
                    )
                  : Container(
                      height: 220,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(child: Text("Görsel yok", style: TextStyle(color: Colors.grey))),
                    ),
            ),
            const SizedBox(height: 16),
            Text(
              '${carDetail!['brand']} ${carDetail!['model']} (${carDetail!['modelYear']})',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 36, 56, 84),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              carDetail!['description'] ?? "Açıklama yok",
              style: TextStyle(fontSize: 16, color: Colors.grey.shade800, height: 1.4),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 20,
              runSpacing: 12,
              children: [
                _infoChip(Icons.color_lens, 'Renk', carDetail!['color']),
                _infoChip(Icons.local_gas_station, 'Yakıt', carDetail!['fuelType']),
                _infoChip(Icons.settings, 'Vites', carDetail!['gearType']),
                _infoChip(Icons.speed, 'Km', carDetail!['mileage'].toString()),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Günlük Ücret: ${carDetail!['dailyPrice']}₺',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 86, 159, 243),
              ),
            ),
            const Divider(height: 40, thickness: 1.2),
            Text(
              'Ortalama Puan: ${carDetail!['averageRating'].toStringAsFixed(1)} / 5',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 14),
            const Text(
              'Yorumlar',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...((carDetail!['reviews'] as List<dynamic>).isEmpty
                ? [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'Henüz yorum yok',
                        style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                      ),
                    )
                  ]
                : (carDetail!['reviews'] as List<dynamic>).map((review) {
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 1.5,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Text(
                          review['userName'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(review['comment']),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(5, (index) {
                            return Icon(
                              index < review['rating'] ? Icons.star : Icons.star_border,
                              color: Colors.amber.shade600,
                              size: 18,
                            );
                          }),
                        ),
                      ),
                    );
                  }).toList()),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, String value) {
    return Chip(
      avatar: Icon(icon, size: 20, color: const Color.fromARGB(255, 86, 159, 243)),
      label: RichText(
        text: TextSpan(
          text: '$label: ',
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
          children: [
            TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.normal, color: Colors.black54),
            )
          ],
        ),
      ),
      backgroundColor: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}

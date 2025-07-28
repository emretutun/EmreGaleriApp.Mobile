import 'package:emregalerimobile/services/api.dart';
import 'package:flutter/material.dart';



class CarDetailPage extends StatelessWidget {
  final Map<String, dynamic> car;

  const CarDetailPage({super.key, required this.car});

  @override
  Widget build(BuildContext context) {
    final String? imagePath = car['imageUrl'];
    final String imageUrl = imagePath != null && imagePath.isNotEmpty
        ? "${ApiService.baseUrl}${imagePath.startsWith("/") ? imagePath : "/$imagePath"}"
        : "";

    List licenseTypes = car['licenseTypes'] ?? [];
    String licenseTypesStr = licenseTypes.isNotEmpty
        ? licenseTypes.map((e) {
            if (e is Map && e.containsKey('name')) {
              return e['name'];
            } else {
              return e.toString();
            }
          }).join(", ")
        : "-";

    String gearTypeStr = "-";
    if (car['gearType'] != null) {
      switch (car['gearType']) {
        case 1:
          gearTypeStr = "Otomatik";
          break;
        case 2:
          gearTypeStr = "Yarı Otomatik";
          break;
        case 3:
          gearTypeStr = "Manuel";
          break;
        default:
          gearTypeStr = car['gearType'].toString();
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("${car['brand'] ?? '-'} ${car['model'] ?? '-'} Detay"),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  imageUrl,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image, size: 150, color: Colors.grey),
                ),
              )
            else
              const Icon(Icons.directions_car, size: 150, color: Colors.grey),

            const SizedBox(height: 24),

            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildInfoRow(Icons.directions_car, "Marka", car['brand']),
                    _buildInfoRow(Icons.model_training, "Model", car['model']),
                    _buildInfoRow(Icons.calendar_today, "Model Yılı", car['modelYear']),
                    _buildInfoRow(Icons.monetization_on, "Günlük Fiyat", "${car['dailyPrice']}₺"),
                    _buildInfoRow(Icons.description, "Açıklama", car['description']),
                    _buildInfoRow(Icons.local_gas_station, "Yakıt Türü", car['fuelType']),
                    _buildInfoRow(Icons.speed, "Kilometre", "${car['mileage']} km"),
                    _buildInfoRow(Icons.settings, "Vites Türü", gearTypeStr),
                    _buildInfoRow(Icons.badge, "Ehliyet Türleri", licenseTypesStr),
                    _buildInfoRow(Icons.color_lens, "Renk", car['color']),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "$title:",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? "-",
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}

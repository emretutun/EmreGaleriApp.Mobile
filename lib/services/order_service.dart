// lib/services/order_service.dart
import 'dart:convert';
import 'package:emregalerimobile/models/order.dart';
import 'package:emregalerimobile/services/api.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class OrderService {
  // Buraya kendi API base URL'ini doğru şekilde yazmalısın!
  final String baseUrl = '${ApiService.baseUrl}/api/myorders';

  Future<List<Order>> fetchMyOrders() async {
    final prefs = await SharedPreferences.getInstance();

    // Token key'i 'jwt_token' olarak login sayfasına uyumlu hale getirildi
    final token = prefs.getString('jwt_token');

    if (token == null) {
      throw Exception("Token bulunamadı.");
    }

    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((json) => Order.fromJson(json)).toList();
    } else {
      throw Exception("Siparişler yüklenemedi. Hata kodu: ${response.statusCode}");
    }
  }
}

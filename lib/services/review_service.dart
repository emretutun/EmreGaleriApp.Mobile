// lib/services/review_service.dart
import 'dart:convert';
import 'package:emregalerimobile/services/api.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ReviewService {
  final String baseUrl = '${ApiService.baseUrl}/api/myorders/reviews';

  Future<void> addReview({
    required int orderId,
    required int carId,
    required int rating,
    required String comment,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) {
      throw Exception("Kullanıcı girişi bulunamadı.");
    }

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'orderId': orderId,
        'carId': carId,
        'rating': rating,
        'comment': comment,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    } else if (response.statusCode == 400) {
      throw Exception("Zaten bu siparişe yorum yaptınız.");
    } else {
      throw Exception('Yorum eklenirken hata oluştu. Hata kodu: ${response.statusCode}');
    }
  }
}

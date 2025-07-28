// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CartItem {
  final int carId;
  final String carName;
  final double dailyPrice;  // int -> double
  final String imageUrl;

  CartItem({
    required this.carId,
    required this.carName,
    required this.dailyPrice,
    required this.imageUrl,
  });

  Map<String, dynamic> toJson() => {
        'carId': carId,
        'carName': carName,
        'dailyPrice': dailyPrice,
        'imageUrl': imageUrl,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        carId: json['carId'],
        carName: json['carName'],
        dailyPrice: (json['dailyPrice'] as num).toDouble(), // int/double karışıklığı için
        imageUrl: json['imageUrl'],
      );
}


class CartService {
  static const String _cartKey = 'emregaleri_cart';

  List<CartItem> _items = [];

  CartService._privateConstructor();

  static final CartService _instance = CartService._privateConstructor();

  factory CartService() {
    return _instance;
  }

 Future<void> loadCart() async {
  final prefs = await SharedPreferences.getInstance();
  final String? jsonString = prefs.getString(_cartKey);
  if (jsonString != null) {
    print("CartService.loadCart: veri bulundu");
    List<dynamic> jsonList = json.decode(jsonString);
    _items = jsonList.map((e) => CartItem.fromJson(e)).toList();
  } else {
    print("CartService.loadCart: boş veri");
    _items = [];
  }
  print("CartService.loadCart: yüklenen item sayısı = ${_items.length}");
}

Future<void> saveCart() async {
  final prefs = await SharedPreferences.getInstance();
  final String jsonString = json.encode(_items.map((e) => e.toJson()).toList());
  await prefs.setString(_cartKey, jsonString);
  print("CartService.saveCart: veri kaydedildi, item sayısı = ${_items.length}");
}


  List<CartItem> get items => List.unmodifiable(_items);

Future<void> addItem(CartItem item) async {
  if (_items.any((e) => e.carId == item.carId)) {
    print("addItem: Bu araç zaten sepette => ${item.carId}");
    return;
  }
  _items.add(item);
  print("addItem: Araç sepete eklendi => ${item.carId}");
  await saveCart();
}


  Future<void> removeItem(int carId) async {
    _items.removeWhere((element) => element.carId == carId);
    await saveCart();
  }

  Future<void> clearCart() async {
    _items.clear();
    await saveCart();
  }
}

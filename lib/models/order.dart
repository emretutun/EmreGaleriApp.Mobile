// lib/models/order.dart

class Order {
  final int id;
  final String status;
  final String startDate;
  final String endDate;
  final double totalPrice;
  final int deliveryStatus; // int tipinde
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    required this.deliveryStatus,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as int,
      status: json['status'] as String,
      startDate: json['startDate'] as String,
      endDate: json['endDate'] as String,
      totalPrice: (json['totalPrice'] as num).toDouble(),
      deliveryStatus: json['deliveryStatus'] as int,
      items: (json['orderItems'] as List)
          .map((item) => OrderItem.fromJson(item))
          .toList(),
    );
  }
}

class OrderItem {
  final int carId;
  final String brand;
  final String model;
  final String imageUrl;

  OrderItem({
    required this.carId,
    required this.brand,
    required this.model,
    required this.imageUrl,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      carId: json['carId'] as int,
      brand: json['brand'] as String,
      model: json['model'] as String,
      imageUrl: json['imageUrl'] as String,
    );
  }
}

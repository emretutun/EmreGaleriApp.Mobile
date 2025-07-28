class Firm {
  final int id;
  final String name;

  Firm({required this.id, required this.name});

  factory Firm.fromJson(Map<String, dynamic> json) {
    return Firm(
      id: json['id'],
      name: json['name'],
    );
  }
}

class StockItem {
  final int id;
  final String productName;
  final int quantity;
  final double purchasePrice;
  final double salePrice;
  final Firm? firm;

  StockItem({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.purchasePrice,
    required this.salePrice,
    this.firm,
  });

  factory StockItem.fromJson(Map<String, dynamic> json) {
    return StockItem(
      id: json['id'],
      productName: json['productName'],
      quantity: json['quantity'],
      purchasePrice: (json['purchasePrice'] as num).toDouble(),
      salePrice: (json['salePrice'] as num).toDouble(),
      firm: json['firm'] != null ? Firm.fromJson(json['firm']) : null,
    );
  }
}

class FirmModel {
  final int id;
  final String name;
  final String address;
  final String contactPerson;
  final String phone;
  final String email;
  final String? notes;

  FirmModel({
    required this.id,
    required this.name,
    required this.address,
    required this.contactPerson,
    required this.phone,
    required this.email,
    this.notes,
  });

  factory FirmModel.fromJson(Map<String, dynamic> json) {
    return FirmModel(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      contactPerson: json['contactPerson'],
      phone: json['phone'],
      email: json['email'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {  
      'id': id,
      'name': name,
      'address': address,
      'contactPerson': contactPerson,
      'phone': phone,
      'email': email,
      'notes': notes,
    };
  }
}

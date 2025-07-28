class PersonelModel {
  final int id;
  final String userId;
  final String userName;
  final String email;       // Yeni
  final String phoneNumber; // Yeni
  final String position;
  final double salary;
  final DateTime startDate;

  PersonelModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.email,
    required this.phoneNumber,
    required this.position,
    required this.salary,
    required this.startDate,
  });

  factory PersonelModel.fromJson(Map<String, dynamic> json) {
    return PersonelModel(
      id: json['id'],
      userId: json['userId'],
      userName: json['userName'],
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      position: json['position'],
      salary: (json['salary'] as num).toDouble(),
      startDate: DateTime.parse(json['startDate']),
    );
  }
}

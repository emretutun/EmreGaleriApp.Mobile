// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:convert';
import 'package:emregalerimobile/models/user_profile_model.dart';
import 'package:emregalerimobile/services/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;





class UserProfileService {
  final String token;

  UserProfileService({required this.token});

  Future<UserProfile> fetchUserProfile() async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/api/UserProfileApi'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return UserProfile.fromJson(jsonData);
    } else {
      throw Exception('Profil yüklenemedi: ${response.statusCode}');
    }
  }
}

class UserProfilePage extends StatefulWidget {
  final String token;

  const UserProfilePage({super.key, required this.token});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  late Future<UserProfile> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = UserProfileService(token: widget.token).fetchUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profilim')),
      body: FutureBuilder<UserProfile>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Profil bulunamadı'));
          }

          final profile = snapshot.data!;

          // Cinsiyet Türkçe gösterimi için küçük dönüşüm örneği
          String genderDisplay = 'Belirtilmemiş';
          if (profile.gender != null) {
            final g = profile.gender!.toLowerCase();
            if (g == 'male') genderDisplay = 'Erkek';
            else if (g == 'female') genderDisplay = 'Kadın';
            else genderDisplay = profile.gender!;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (profile.pictureUrl != null)
                  CircleAvatar(
                    radius: 60,
                    backgroundImage:
                        NetworkImage('${ApiService.baseUrl}/userpictures/${profile.pictureUrl}'),
                  )
                else
                  const CircleAvatar(
                    radius: 60,
                    child: Icon(Icons.person, size: 60),
                  ),
                const SizedBox(height: 16),
                Text(profile.userName,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text(profile.email, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.badge),
                  title: Text(profile.nationalId ?? 'Belirtilmemiş'),
                  subtitle: const Text('TC Kimlik No'),
                ),
                ListTile(
                  leading: const Icon(Icons.cake),
                  title: Text(profile.birthDate != null
                      ? '${profile.birthDate!.day}.${profile.birthDate!.month}.${profile.birthDate!.year}'
                      : 'Belirtilmemiş'),
                  subtitle: const Text('Doğum Tarihi'),
                ),
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(genderDisplay),
                  subtitle: const Text('Cinsiyet'),
                ),
                ListTile(
                  leading: const Icon(Icons.directions_car),
                  title:
                      Text(profile.drivingExperienceYears?.toString() ?? 'Belirtilmemiş'),
                  subtitle: const Text('Sürüş Deneyimi (Yıl)'),
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Ehliyet Türleri',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                ...profile.licenseTypes.map((lt) => ListTile(
                      leading: const Icon(Icons.confirmation_num),
                      title: Text(lt.name),
                    )),
              ],
            ),
          );
        },
      ),
    );
  }
}

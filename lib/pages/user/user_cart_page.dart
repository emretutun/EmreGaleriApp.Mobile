// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:emregalerimobile/services/card_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:emregalerimobile/services/api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:emregalerimobile/services/signalr_service.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<CartItem> items = [];
  DateTime? startDate;
  DateTime? endDate;
  bool isLoading = false;
  String? token;

  late SignalRService signalRService;
  Set<int> lockedCarIds = {}; // Kilitlenen araçlar

  @override
  void initState() {
    super.initState();
    loadTokenAndCart();
  }

  @override
  void dispose() {
    signalRService.stopConnection();
    super.dispose();
  }

  Future<void> loadTokenAndCart() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('jwt_token');
    await CartService().loadCart();
    setState(() {
      items = CartService().items;
    });

    // SignalR bağlantısını başlat
    await _startSignalR();
  }

  Future<void> _startSignalR() async {
    if (token == null) return;

    signalRService = SignalRService();
    await signalRService.startConnection(token!);

    // Kilitlenen araçları dinle
    signalRService.onCarLocked((carId) async {
      if (!lockedCarIds.contains(carId)) {
        setState(() {
          lockedCarIds.add(carId);
        });

        // Araç bilgisi bul
        final foundItem = items.firstWhere(
          (c) => c.carId == carId,
          orElse: () => CartItem(carId: 0, carName: 'Bilinmeyen', dailyPrice: 0, imageUrl: ''),
        );

        final carName = foundItem.carName;

        // Eğer araç sepetteyse popup göster ve sepeti temizle
        if (carName != 'Bilinmeyen') {
          await showDialog(
            context: context,
            barrierDismissible: false, // kullanıcı popup dışında tıklayamaz
            builder: (context) {
              return AlertDialog(
                title: const Text('Araç Kiralandı'),
                content: Text('⚠️ "$carName" aracı başka kullanıcı tarafından kiralandı ve sepetiniz temizlenecek.'),
                actions: [
                  TextButton(
                    onPressed: () async {
                      Navigator.of(context).pop();

                      // Sepeti temizle
                      await CartService().clearCart();
                      await loadCart();

                      setState(() {
                        lockedCarIds.clear();
                        startDate = null;
                        endDate = null;
                      });
                    },
                    child: const Text('Tamam'),
                  ),
                ],
              );
            },
          );
        } else {
          // Araç sepette yoksa normal snackbar göster
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('⚠️ Bir araç başkası tarafından kiralandı (ID: $carId).')),
          );
        }
      }
    });

    // Kilit açılan araçları dinle
    signalRService.onCarUnlocked((carId) {
      if (lockedCarIds.contains(carId)) {
        setState(() {
          lockedCarIds.remove(carId);
        });
  
      }
    });

    // Sepetteki araçların müsaitliklerini kontrol et
    for (var item in items) {
      bool available = await signalRService.checkIfCarAvailable(item.carId);
      if (!available) {
        lockedCarIds.add(item.carId);
      }
    }
    setState(() {});
  }

  Future<void> loadCart() async {
    await CartService().loadCart();
    setState(() {
      items = CartService().items;
    });
  }

  Future<void> removeItem(int carId) async {
    await CartService().removeItem(carId);
    lockedCarIds.remove(carId);
    await loadCart();
  }

  Future<void> pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        startDate = picked;
        if (endDate != null && endDate!.isBefore(startDate!)) {
          endDate = null;
        }
      });
    }
  }

  Future<void> pickEndDate() async {
    if (startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce başlangıç tarihi seçin')),
      );
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: endDate ?? startDate!.add(const Duration(days: 1)),
      firstDate: startDate!.add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 366)),
    );
    if (picked != null) {
      setState(() {
        endDate = picked;
      });
    }
  }

  int get rentalDays {
    if (startDate == null || endDate == null) return 0;
    return endDate!.difference(startDate!).inDays;
  }

  double get totalPrice {
    if (rentalDays <= 0) return 0.0;
    double sum = 0;
    for (var item in items) {
      sum += item.dailyPrice * rentalDays;
    }
    return sum;
  }

  Future<void> confirmOrder() async {
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sepetiniz boş')),
      );
      return;
    }

    if (startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tarih aralığını seçin')),
      );
      return;
    }

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Giriş yapmanız gerekiyor')),
      );
      return;
    }

    // Kiralanacak araçların kilitli olmadığını kontrol et ve kilitle
    for (var item in items) {
      if (lockedCarIds.contains(item.carId)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('⚠️ "${item.carName}" aracı başka kullanıcı tarafından kilitlendi, kiralanamaz.')),
        );
        return;
      }
      bool locked = await signalRService.lockCar(item.carId);
      if (!locked) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('⚠️ "${item.carName}" aracı kiralanırken başka kullanıcı tarafından kilitlendi.')),
        );
        return;
      }
    }

    setState(() {
      isLoading = true;
    });

    final url = Uri.parse('${ApiService.baseUrl}/api/cartapi/create-order');

    final body = {
      'startDate': startDate!.toIso8601String(),
      'endDate': endDate!.toIso8601String(),
      'cartItems': items
          .map((c) => {
                'carId': c.carId,
                'dailyPrice': c.dailyPrice,
              })
          .toList(),
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      print("API response code: ${response.statusCode}");
      print("API response body: ${response.body}");

      if (response.statusCode == 200) {
        // Sipariş başarılı, araç kilidini aç
        for (var item in items) {
          await signalRService.unlockCar(item.carId);
        }

        await CartService().clearCart();
        await loadCart();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sipariş başarıyla oluşturuldu')),
        );

        setState(() {
          startDate = null;
          endDate = null;
          lockedCarIds.clear();
        });
      } else {
        String errorMsg = 'Bir hata oluştu';
        if (response.body.isNotEmpty) {
          try {
            final decoded = jsonDecode(response.body);
            if (decoded is Map && decoded.containsKey('message')) {
              errorMsg = decoded['message'];
            }
          } catch (_) {}
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );

        // Hata olursa kilit aç
        for (var item in items) {
          await signalRService.unlockCar(item.carId);
        }
      }
    } catch (e) {
      print("HTTP Exception: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );

      // Hata durumunda da kilidi aç
      for (var item in items) {
        await signalRService.unlockCar(item.carId);
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      backgroundColor: const Color.fromARGB(255, 86, 159, 243),
      title: const Text('Sepetim'),
      centerTitle: true,
      elevation: 4,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
    ),
    body: items.isEmpty
        ? const Center(
            child: Text(
              'Sepetin boş',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          )
        : Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final c = items[index];
                    final isLocked = lockedCarIds.contains(c.carId);
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      color: isLocked ? Colors.red.shade100 : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: isLocked
                            ? BorderSide(color: Colors.red.shade400, width: 1.5)
                            : BorderSide.none,
                      ),
                      elevation: 2,
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: c.imageUrl.isNotEmpty
                              ? Image.network(
                                  c.imageUrl,
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 70,
                                      height: 70,
                                      color: Colors.grey.shade300,
                                      child: const Icon(Icons.broken_image, color: Colors.grey),
                                    );
                                  },
                                )
                              : Container(
                                  width: 70,
                                  height: 70,
                                  color: Colors.grey.shade300,
                                  child: const Icon(Icons.directions_car, color: Colors.grey),
                                ),
                        ),
                        title: Text(
                          c.carName,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                        subtitle: Text(
                          'Günlük: ${c.dailyPrice.toStringAsFixed(2)}₺',
                          style: const TextStyle(color: Colors.black87),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: isLocked
                              ? null
                              : () async {
                                  await removeItem(c.carId);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('${c.carName} sepetten çıkarıldı')),
                                  );
                                },
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: pickStartDate,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 86, 159, 243),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              startDate == null
                                  ? 'Başlangıç Tarihi Seç'
                                  : 'Başlangıç: ${startDate!.toLocal().toString().split(" ")[0]}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: pickEndDate,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 86, 159, 243),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              endDate == null
                                  ? 'Bitiş Tarihi Seç'
                                  : 'Bitiş: ${endDate!.toLocal().toString().split(" ")[0]}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Toplam Gün: $rentalDays',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'Toplam Tutar: ${totalPrice.toStringAsFixed(2)} ₺',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color.fromARGB(255, 86, 159, 243),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton(
                      onPressed: isLoading ? null : confirmOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 86, 159, 243),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 26,
                              height: 26,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Text(
                              'Siparişi Onayla',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () async {
                        await CartService().clearCart();
                        await loadCart();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Sepet temizlendi')),
                        );
                      },
                      child: const Text(
                        'Sepeti Temizle',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
  );
}
}
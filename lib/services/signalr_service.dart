// ignore_for_file: avoid_print

import 'package:signalr_core/signalr_core.dart';
import 'package:emregalerimobile/services/api.dart';

class SignalRService {
  static final SignalRService _instance = SignalRService._internal();
  late HubConnection _hubConnection;

  factory SignalRService() {
    return _instance;
  }

  SignalRService._internal();

  Future<void> startConnection(String accessToken) async {
    _hubConnection = HubConnectionBuilder()
        .withUrl(
          '${ApiService.baseUrl}/rentalhub',
          HttpConnectionOptions(
            accessTokenFactory: () async => accessToken,
            logging: (level, message) => print('SignalR [$level]: $message'),
          ),
        )
        .withAutomaticReconnect()
        .build();

    
    _hubConnection.onclose((error) => print("🔴 SignalR kapandı: $error"));
    
    _hubConnection.onreconnected((connectionId) => print("🟢 SignalR yeniden bağlandı: $connectionId"));
    
    _hubConnection.onreconnecting((error) => print("🟡 SignalR yeniden bağlanıyor: $error"));

    try {
      await _hubConnection.start();
      print("✅ SignalR bağlantısı kuruldu.");
    } catch (e) {
      print("❌ SignalR bağlantı hatası: $e");
    }
  }

  Future<void> stopConnection() async {
    await _hubConnection.stop();
    print("🛑 SignalR bağlantısı kapatıldı.");
  }

  /// Kiralanan aracı bildir
  Future<void> notifyCarRented(int carId) async {
    try {
      await _hubConnection.invoke('NotifyCarRented', args: [carId]);
      print("📢 NotifyCarRented çağrıldı: $carId");
    } catch (e) {
      print("❌ NotifyCarRented hatası: $e");
    }
  }

  /// Kilitlenen araç geldiğinde callback
  void onCarLocked(Function(int) callback) {
    _hubConnection.on('CarLocked', (arguments) {
      if (arguments != null && arguments.isNotEmpty && arguments[0] is int) {
        callback(arguments[0] as int);
      }
    });
  }

  /// Kilidi açılan araç geldiğinde callback
  void onCarUnlocked(Function(int) callback) {
    _hubConnection.on('CarUnlocked', (arguments) {
      if (arguments != null && arguments.isNotEmpty && arguments[0] is int) {
        callback(arguments[0] as int);
      }
    });
  }

  /// Aracın müsait olup olmadığını sorgula
  Future<bool> checkIfCarAvailable(int carId) async {
    try {
      final result = await _hubConnection.invoke('CheckIfCarAvailable', args: [carId]);
      if (result is bool) return result;
      return false;
    } catch (e) {
      print("❌ CheckIfCarAvailable hatası: $e");
      return false;
    }
  }

  /// Aracı kilitle (kiralama başlarken)
  Future<bool> lockCar(int carId) async {
    try {
      final result = await _hubConnection.invoke('LockCar', args: [carId]);
      if (result is bool) return result;
      return false;
    } catch (e) {
      print("❌ LockCar hatası: $e");
      return false;
    }
  }

  /// Kilidi kaldır
  Future<void> unlockCar(int carId) async {
    try {
      await _hubConnection.invoke('UnlockCar', args: [carId]);
    } catch (e) {
      print("❌ UnlockCar hatası: $e");
    }
  }
}

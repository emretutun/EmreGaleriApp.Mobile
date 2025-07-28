// ignore_for_file: avoid_print

import 'package:signalr_core/signalr_core.dart';
import 'package:emregalerimobile/services/api.dart';

class SignalRService {
  static final SignalRService _instance = SignalRService._internal();
  HubConnection? _hubConnection;

  factory SignalRService() {
    return _instance;
  }

  SignalRService._internal();

  /// SignalR bağlantısını başlat
  Future<void> startConnection(String accessToken) async {
    if (_hubConnection != null && _hubConnection!.state == HubConnectionState.connected) {
      print("🔄 Zaten bağlantı kurulu.");
      return;
    }

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

    _hubConnection!.onclose((error) => print("🔴 SignalR kapandı: $error"));
    _hubConnection!.onreconnected((connectionId) => print("🟢 SignalR yeniden bağlandı: $connectionId"));
    _hubConnection!.onreconnecting((error) => print("🟡 SignalR yeniden bağlanıyor: $error"));

    try {
      await _hubConnection!.start();
      print("✅ SignalR bağlantısı kuruldu.");
    } catch (e) {
      print("❌ SignalR bağlantı hatası: $e");
    }
  }

  /// SignalR bağlantısını durdur
  Future<void> stopConnection() async {
    if (_hubConnection != null && _hubConnection!.state != HubConnectionState.disconnected) {
      await _hubConnection!.stop();
      print("🛑 SignalR bağlantısı kapatıldı.");
    }
  }

  /// Bağlantı durumu getter'ı (CartPage için)
  bool get connectionStarted => _hubConnection?.state == HubConnectionState.connected;

  /// Aracı kiralandı olarak bildir
  Future<void> notifyCarRented(int carId) async {
    try {
      await _hubConnection?.invoke('NotifyCarRented', args: [carId]);
      print("📢 NotifyCarRented çağrıldı: $carId");
    } catch (e) {
      print("❌ NotifyCarRented hatası: $e");
    }
  }

  /// Kilitlenen aracı dinle
  void onCarLocked(Function(int) callback) {
    _hubConnection?.on('CarLocked', (arguments) {
      if (arguments != null && arguments.isNotEmpty && arguments[0] is int) {
        callback(arguments[0] as int);
      }
    });
  }

  /// Kilidi açılan aracı dinle
  void onCarUnlocked(Function(int) callback) {
    _hubConnection?.on('CarUnlocked', (arguments) {
      if (arguments != null && arguments.isNotEmpty && arguments[0] is int) {
        callback(arguments[0] as int);
      }
    });
  }

  /// Aracın müsaitlik durumu
  Future<bool> checkIfCarAvailable(int carId) async {
    try {
      final result = await _hubConnection?.invoke('CheckIfCarAvailable', args: [carId]);
      if (result is bool) return result;
    } catch (e) {
      print("❌ CheckIfCarAvailable hatası: $e");
    }
    return false;
  }

  /// Aracı kilitle
  Future<bool> lockCar(int carId) async {
    try {
      final result = await _hubConnection?.invoke('LockCar', args: [carId]);
      if (result is bool) return result;
    } catch (e) {
      print("❌ LockCar hatası: $e");
    }
    return false;
  }

  /// Aracın kilidini kaldır
  Future<void> unlockCar(int carId) async {
    try {
      await _hubConnection?.invoke('UnlockCar', args: [carId]);
    } catch (e) {
      print("❌ UnlockCar hatası: $e");
    }
  }
}

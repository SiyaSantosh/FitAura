import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'api_service.dart';

/// Service responsible for managing the global Socket.io real-time connection.
class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? socket;

  /// Connects to the Socket.io server and registers the given [userId].
  void connect(int userId) {
    if (socket != null && socket!.connected) return;

    socket = IO.io(ApiService.baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket!.connect();

    socket!.onConnect((_) {
      print('Connected to Socket.io server');
      
      socket!.emit('register', userId);
    });

    socket!.onDisconnect((_) => print('Disconnected from Socket.io server'));

    socket!.onConnectError((data) => print('Connect Error: $data'));
    socket!.onError((data) => print('Error: $data'));
  }

  /// Disconnects from the Socket.io server and clears the socket instance.
  void disconnect() {
    socket?.disconnect();
    socket = null;
  }
}


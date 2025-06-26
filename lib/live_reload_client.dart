import 'dart:js_interop';
import 'dart:convert';

@JS()
external WebSocket createWebSocket(String url);

@JS()
external Window get window;

@JS()
@anonymous
class Window {
  external void reload();
}

@JS()
@anonymous
class Event {
  // Base event class
}

@JS()
@anonymous
class WebSocket {
  external void close();
  external Stream<Event> get onOpen;
  external Stream<MessageEvent> get onMessage;
  external Stream<Event> get onError;
  external Stream<CloseEvent> get onClose;
}

@JS()
@anonymous
class MessageEvent extends Event {
  external String get data;
}

@JS()
@anonymous
class CloseEvent extends Event {
  external int get code;
  external String get reason;
}

class LiveReloadClient {
  WebSocket? _socket;
  static const String _serverUrl = 'ws://localhost:8081';

  void connect() {
    try {
      _socket = createWebSocket(_serverUrl);

      _socket!.onOpen.listen((event) {
        print('🔌 Connected to live reload server');
      });

      _socket!.onMessage.listen((event) {
        final data = jsonDecode(event.data);
        if (data['type'] == 'reload') {
          print('🔄 Live reload triggered');
          window.reload();
        }
      });

      _socket!.onError.listen((event) {
        print('❌ WebSocket error: $event');
      });

      _socket!.onClose.listen((event) {
        print('🔌 Disconnected from live reload server');
        // Try to reconnect after a delay
        Future.delayed(Duration(seconds: 2), () {
          connect();
        });
      });
    } catch (e) {
      print('❌ Failed to connect to live reload server: $e');
    }
  }

  void disconnect() {
    _socket?.close();
  }
}

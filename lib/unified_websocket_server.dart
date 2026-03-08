import 'dart:io';
import 'dart:convert';
import 'config.dart';

/// One server to rule them all: handles hot reload, auto reload, error overlays, and instant updating.
class UnifiedWebSocketServer {
  HttpServer? _server;
  final List<WebSocket> _clients = [];
  int? _boundPort;
  
  int get port => _boundPort ?? FlutsimConfig.unifiedWebSocketPort;

  Future<void> start({int? preferPort}) async {
    try {
      int targetPort = preferPort ?? FlutsimConfig.unifiedWebSocketPort;
      _server = await HttpServer.bind(InternetAddress.anyIPv4, targetPort);
      _boundPort = _server!.port;
      
      _server!.listen((HttpRequest request) {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          WebSocketTransformer.upgrade(request).then((WebSocket webSocket) {
            _handleWebSocket(webSocket);
          });
        } else {
          request.response.statusCode = 400;
          request.response.close();
        }
      });
    } catch (e) {
      // If the port is taken, try finding another one just like server.dart does
      print('❌ Failed to start Unified WebSocket server: $e');
    }
  }

  void _handleWebSocket(WebSocket webSocket) {
    _clients.add(webSocket);

    webSocket.listen(
      (data) {
        // Handle client responses if necessary
      },
      onDone: () {
        _clients.remove(webSocket);
      },
      onError: (error) {
        _clients.remove(webSocket);
      },
    );
  }

  void _broadcast(Map<String, dynamic> payload) {
    if (_clients.isEmpty) return;
    
    final message = jsonEncode(payload);
    
    _clients.removeWhere((client) {
      try {
        client.add(message);
        return false;
      } catch (e) {
        return true; // Remove dead clients
      }
    });
  }

  /// Sends the instant hot reload signal to the flutter engine via JS.
  void triggerHotReload() {
    _broadcast({
      'type': 'hot_reload',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Sends a brutal full page refresh signal.
  void triggerAutoReload() {
    _broadcast({
      'type': 'auto_reload',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Send an instant UI update payload
  void sendInstantUIUpdate(List<Map<String, dynamic>> changes) {
    _broadcast({
      'type': 'instant_update',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'changes': changes,
    });
  }
  
  /// Sends an error object to render an overlay on the device.
  void sendError(String errorMessage) {
    _broadcast({
      'type': 'error',
      'message': errorMessage,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }
  
  /// Sends a signal that the error has been cleared (e.g. successful compile).
  void clearError() {
    _broadcast({
      'type': 'clear_error',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  void stop() {
    _server?.close();
    for (final client in _clients) {
      client.close();
    }
    _clients.clear();
  }
}

import 'dart:io';
import 'dart:convert';
import 'config.dart';

/// Dedicated instant UI update server for DOM manipulation
class InstantUIServer {
  HttpServer? _server;
  final List<WebSocket> _clients = [];

  Future<void> start() async {
    try {
      _server = await HttpServer.bind(
          InternetAddress.anyIPv4, FlutsimConfig.instantUIPort);
      print(
          '⚡ Instant UI update server started on port ${FlutsimConfig.instantUIPort}');

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
      print('❌ Failed to start instant UI update server: $e');
    }
  }

  void _handleWebSocket(WebSocket webSocket) {
    _clients.add(webSocket);
    print(
        '⚡ Instant UI update client connected. Total clients: ${_clients.length}');

    webSocket.listen(
      (data) {
        print('⚡ Instant UI update message: $data');
      },
      onDone: () {
        _clients.remove(webSocket);
        print(
            '⚡ Instant UI update client disconnected. Total clients: ${_clients.length}');
      },
      onError: (error) {
        print('❌ Instant UI update WebSocket error: $error');
        _clients.remove(webSocket);
      },
    );
  }

  /// Send instant UI update to all connected browsers
  void sendInstantUIUpdate(List<Map<String, dynamic>> changes) {
    if (_clients.isEmpty) {
      print('⚠️  No instant UI update clients connected');
      return;
    }

    final updateMessage = jsonEncode({
      'type': 'instant_update',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'changes': changes,
    });

    _clients.removeWhere((client) {
      try {
        client.add(updateMessage);
        return false;
      } catch (e) {
        print('❌ Failed to send instant UI update to client: $e');
        return true;
      }
    });

    print('⚡ Instant UI update sent to ${_clients.length} browsers');
  }

  /// Send a simple text update
  void updateText(String selector, String text) {
    final changes = [
      {
        'action': 'update_text',
        'selector': selector,
        'text': text,
      }
    ];
    sendInstantUIUpdate(changes);
  }

  /// Send a style update
  void updateStyle(String selector, Map<String, String> style) {
    final changes = [
      {
        'action': 'update_style',
        'selector': selector,
        'style': style,
      }
    ];
    sendInstantUIUpdate(changes);
  }

  /// Send an attribute update
  void updateAttribute(String selector, String attribute, String value) {
    final changes = [
      {
        'action': 'update_attribute',
        'selector': selector,
        'attribute': attribute,
        'value': value,
      }
    ];
    sendInstantUIUpdate(changes);
  }

  /// Send an element replacement
  void replaceElement(String selector, String html) {
    final changes = [
      {
        'action': 'replace_element',
        'selector': selector,
        'html': html,
      }
    ];
    sendInstantUIUpdate(changes);
  }

  /// Send a Flutter widget update
  void updateFlutterWidget(String widgetId, Map<String, dynamic> properties) {
    final changes = [
      {
        'action': 'update_flutter_widget',
        'widgetId': widgetId,
        'properties': properties,
      }
    ];
    sendInstantUIUpdate(changes);
  }

  void stop() {
    _server?.close();
    for (final client in _clients) {
      client.close();
    }
    _clients.clear();
    print('⚡ Instant UI update server stopped');
  }
}

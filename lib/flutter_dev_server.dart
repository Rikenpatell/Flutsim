import 'dart:io';
import 'dart:convert';
import 'dart:async';

/// Communicates with Flutter's development server to trigger hot reload
class FlutterDevServer {
  static const int _defaultPort = 8081;
  static const String _defaultHost = 'localhost';

  final String host;
  final int port;

  FlutterDevServer({
    this.host = _defaultHost,
    this.port = _defaultPort,
  });

  /// Trigger hot reload via Flutter's development server
  Future<bool> triggerHotReload() async {
    try {
      final url = 'http://$host:$port/__flutter_web_hot_reload__';

      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(url));

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      client.close();

      if (response.statusCode == 200) {
        print('✅ Hot reload triggered successfully via Flutter dev server');
        return true;
      } else {
        print('❌ Hot reload failed: ${response.statusCode} - $responseBody');
        return false;
      }
    } catch (e) {
      print('❌ Failed to trigger hot reload: $e');
      return false;
    }
  }

  /// Check if Flutter development server is running
  Future<bool> isServerRunning() async {
    try {
      final url = 'http://$host:$port/__flutter_web_hot_reload__';

      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(url));

      final response = await request.close();
      client.close();

      return response.statusCode == 200 || response.statusCode == 404;
    } catch (e) {
      return false;
    }
  }

  /// Get Flutter development server status
  Future<Map<String, dynamic>?> getServerStatus() async {
    try {
      final url = 'http://$host:$port/__flutter_web_status__';

      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(url));

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      client.close();

      if (response.statusCode == 200) {
        return jsonDecode(responseBody) as Map<String, dynamic>;
      }
    } catch (e) {
      print('❌ Failed to get server status: $e');
    }
    return null;
  }
}

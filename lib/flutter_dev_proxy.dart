import 'dart:io';
import 'dart:convert';
import 'flutsim_client.dart';

/// Proxy server that sits in front of Flutter development server
/// to inject auto reload scripts
class FlutterDevProxy {
  HttpServer? _server;
  final int proxyPort;
  final int flutterPort;
  final int unifiedPort;

  FlutterDevProxy({
    required this.proxyPort,
    required this.flutterPort,
    required this.unifiedPort,
  });

  Future<void> start() async {
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, proxyPort);
      print('🔄 Flutter dev proxy started on port $proxyPort');
      print('🔄 Proxying to Flutter dev server on port $flutterPort');

      _server!.listen((HttpRequest request) async {
        await _handleRequest(request);
      });
    } catch (e) {
      print('❌ Failed to start Flutter dev proxy: $e');
    }
  }

  Future<void> _handleRequest(HttpRequest request) async {
    try {
      // Forward the request to the Flutter development server
      final flutterUrl = 'http://localhost:$flutterPort${request.uri}';

      // Create HTTP client
      final client = HttpClient();

      // Create request to Flutter dev server
      final proxyRequest =
          await client.openUrl(request.method, Uri.parse(flutterUrl));

      // Copy headers
      request.headers.forEach((name, values) {
        proxyRequest.headers.set(name, values);
      });

      // Copy body if present
      if (request.contentLength > 0) {
        final bodyBytes = await request.fold<List<int>>(
          <int>[],
          (list, data) => list..addAll(data),
        );
        proxyRequest.add(bodyBytes);
      }

      // Send request and get response
      final proxyResponse = await proxyRequest.close();

      // Create response for client
      final clientResponse = request.response;
      clientResponse.statusCode = proxyResponse.statusCode;

      // Copy response headers
      proxyResponse.headers.forEach((name, values) {
        clientResponse.headers.set(name, values);
      });

      // Handle HTML responses to inject auto reload script
      final contentType = proxyResponse.headers.value('content-type') ?? '';
      if (contentType.contains('text/html')) {
        // Read the response body
        final bodyBytes = await proxyResponse.fold<List<int>>(
          <int>[],
          (list, data) => list..addAll(data),
        );
        final body = utf8.decode(bodyBytes);

        // Inject unified client script
        String modifiedBody = FlutSimClient.injectScript(body, unifiedPort);

        // Send modified response with proper UTF-8 encoding
        final modifiedBytes = utf8.encode(modifiedBody);
        clientResponse.headers.set('content-type', 'text/html; charset=utf-8');
        clientResponse.headers
            .set('content-length', modifiedBytes.length.toString());
        clientResponse.add(modifiedBytes);
      } else {
        // For non-HTML responses, stream directly
        await proxyResponse.pipe(clientResponse);
      }

      await clientResponse.close();
      client.close();
    } catch (e) {
      print('❌ Proxy error: $e');
      request.response.statusCode = 500;
      request.response.write('Proxy error: $e');
      await request.response.close();
    }
  }

  void stop() {
    _server?.close();
    print('🔄 Flutter dev proxy stopped');
  }
}

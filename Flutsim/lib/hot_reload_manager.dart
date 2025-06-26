import 'dart:io';
import 'dart:convert';

/// Manages hot reload functionality for instant UI updates
class HotReloadManager {
  static const String _hotReloadScript = '''
<script>
// Flutsim Hot Reload System
(function() {
  const ws = new WebSocket('ws://' + window.location.hostname + ':8082');
  
  ws.onopen = function() {
    console.log('🔥 Flutsim Hot Reload connected');
  };
  
  ws.onmessage = function(event) {
    try {
      const data = JSON.parse(event.data);
      if (data.type === 'hot_reload') {
        console.log('🔥 Hot reload triggered');
        // Trigger Flutter's internal hot reload
        if (window.flutter_inappwebview) {
          window.flutter_inappwebview.callHandler('hotReload');
        }
      }
    } catch (e) {
      console.error('Hot reload error:', e);
    }
  };
  
  ws.onerror = function(error) {
    console.log('❌ Hot reload WebSocket error:', error);
  };
  
  ws.onclose = function() {
    console.log('🔌 Hot reload disconnected');
  };
})();
</script>
''';

  /// Inject hot reload script into HTML
  static String injectHotReloadScript(String html) {
    if (html.contains('</body>')) {
      return html.replaceFirst('</body>', '$_hotReloadScript</body>');
    }
    return html + _hotReloadScript;
  }

  /// Send hot reload update to connected clients
  static void sendHotReloadUpdate(WebSocket client) {
    try {
      final message = jsonEncode({
        'type': 'hot_reload',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      client.add(message);
    } catch (e) {
      print('❌ Failed to send hot reload update: $e');
    }
  }
}

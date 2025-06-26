import 'dart:io';
import 'dart:convert';

/// Manages automatic browser reload functionality
class BrowserAutoReload {
  static const String _autoReloadScript = '''
<script>
// Browser Auto Reload System
(function() {
  let autoReloadEnabled = true;
  let reloadCount = 0;
  const maxReloads = 100; // Prevent infinite reloads
  
  // Connect to Flutsim auto reload server
  const ws = new WebSocket('ws://' + window.location.hostname + ':8084');
  
  ws.onopen = function() {
    console.log('🔄 Browser auto reload connected');
  };
  
  ws.onmessage = function(event) {
    if (!autoReloadEnabled) return;
    
    try {
      const data = JSON.parse(event.data);
      
      if (data.type === 'auto_reload') {
        console.log('🔄 Auto reloading page...');
        
        // Check if we haven't exceeded max reloads
        if (reloadCount < maxReloads) {
          reloadCount++;
          
          // Add a small delay to ensure changes are processed
          setTimeout(function() {
            window.location.reload();
          }, 100);
        } else {
          console.warn('⚠️ Max reloads reached, stopping auto reload');
          autoReloadEnabled = false;
        }
      }
    } catch (e) {
      console.error('Auto reload error:', e);
    }
  };
  
  ws.onerror = function(error) {
    console.log('❌ Auto reload WebSocket error:', error);
  };
  
  ws.onclose = function() {
    console.log('🔌 Auto reload disconnected');
    // Try to reconnect after 2 seconds
    setTimeout(function() {
      window.location.reload();
    }, 2000);
  };
  
  // Expose functions for manual control
  window.flutsimAutoReload = {
    enable: () => { autoReloadEnabled = true; },
    disable: () => { autoReloadEnabled = false; },
    reload: () => { window.location.reload(); },
    resetCount: () => { reloadCount = 0; }
  };
})();
</script>
''';

  /// Inject auto reload script into HTML
  static String injectAutoReloadScript(String html) {
    if (html.contains('</body>')) {
      return html.replaceFirst('</body>', '$_autoReloadScript</body>');
    }
    return html + _autoReloadScript;
  }

  /// Send auto reload signal to connected browsers
  static void sendAutoReloadSignal(WebSocket client) {
    try {
      final message = jsonEncode({
        'type': 'auto_reload',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'reloadCount': 0,
      });

      client.add(message);
    } catch (e) {
      print('❌ Failed to send auto reload signal: $e');
    }
  }
}

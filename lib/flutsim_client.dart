class FlutSimClient {
  /// Generates the single unified JS script to inject into the `index.html`.
  /// We pass the [port] dynamically so it always connects correctly.
  static String injectScript(String body, int port) {
    final script = '''
<script>
// FlutSim Unified Client
(function() {
  const ws = new WebSocket('ws://' + window.location.hostname + ':$port');
  
  ws.onopen = function() {
    console.log('⚡ FlutSim Unified Client connected.');
  };
  
  ws.onmessage = function(event) {
    try {
      const data = JSON.parse(event.data);
      
      if (data.type === 'hot_reload') {
        if (window.flutter_inappwebview) {
          window.flutter_inappwebview.callHandler('hotReload');
        } else {
          // Standard web fallback if inappwebview isn't available
          console.log('🔥 Hot reload triggered natively');
        }
      } 
      else if (data.type === 'auto_reload') {
        window.location.reload();
      }
      else if (data.type === 'error') {
        showErrorOverlay(data.message);
      }
      else if (data.type === 'clear_error') {
        clearErrorOverlay();
      }
      else if (data.type === 'instant_update') {
        applyUIChanges(data.changes);
      }
    } catch (e) {
      console.error('FlutSim message error:', e);
    }
  };
  
  ws.onclose = function() {
    console.log('🔌 FlutSim disconnected. Attempting reconnect...');
    setTimeout(() => window.location.reload(), 2000);
  };
  
  // --- Error Overlay Logic ---
  function showErrorOverlay(message) {
    clearErrorOverlay(); // Remove existing if any
    
    const overlay = document.createElement('div');
    overlay.id = 'flutsim-error-overlay';
    overlay.style.position = 'fixed';
    overlay.style.top = '0';
    overlay.style.left = '0';
    overlay.style.width = '100vw';
    overlay.style.height = '100vh';
    overlay.style.backgroundColor = 'rgba(255, 0, 0, 0.9)';
    overlay.style.color = '#fff';
    overlay.style.zIndex = '999999';
    overlay.style.display = 'flex';
    overlay.style.flexDirection = 'column';
    overlay.style.padding = '2rem';
    overlay.style.boxSizing = 'border-box';
    overlay.style.fontFamily = 'monospace';
    overlay.style.overflowY = 'auto';
    
    const title = document.createElement('h1');
    title.innerText = 'Flutter Compilation Error';
    title.style.margin = '0 0 1rem 0';
    
    const pre = document.createElement('pre');
    pre.innerText = message;
    pre.style.whiteSpace = 'pre-wrap';
    pre.style.wordBreak = 'break-word';
    pre.style.backgroundColor = 'rgba(0,0,0,0.3)';
    pre.style.padding = '1rem';
    pre.style.borderRadius = '8px';
    
    overlay.appendChild(title);
    overlay.appendChild(pre);
    document.body.appendChild(overlay);
  }
  
  function clearErrorOverlay() {
    const overlay = document.getElementById('flutsim-error-overlay');
    if (overlay) {
      overlay.remove();
    }
  }

  // --- Instant UI Logic ---
  function applyUIChanges(changes) {
    if (!changes || !Array.isArray(changes)) return;
    changes.forEach(change => {
      try {
        if (change.action === 'update_text') {
           const el = document.querySelector(change.selector);
           if (el) el.textContent = change.text;
        }
      } catch (e) {}
    });
  }
})();
</script>
''';

    if (body.contains('</body>')) {
      return body.replaceFirst('</body>', '$script</body>');
    }
    return body + script;
  }
}

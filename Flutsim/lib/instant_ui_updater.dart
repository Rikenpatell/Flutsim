import 'dart:convert';

/// Manages instant UI updates without page reload
class InstantUIUpdater {
  static const String _instantUpdateScript = '''
<script>
// Instant UI Update System
(function() {
  let updateEnabled = true;
  let updateCount = 0;
  const maxUpdates = 1000; // Higher limit for UI updates
  
  // Connect to Flutsim instant update server
  const ws = new WebSocket('ws://' + window.location.hostname + ':8085');
  
  ws.onopen = function() {
    console.log('⚡ Instant UI updater connected');
  };
  
  ws.onmessage = function(event) {
    if (!updateEnabled) return;
    
    try {
      const data = JSON.parse(event.data);
      
      if (data.type === 'instant_update') {
        console.log('⚡ Applying instant UI update...');
        
        if (updateCount < maxUpdates) {
          updateCount++;
          
          // Apply the UI changes
          applyUIChanges(data.changes);
        } else {
          console.warn('⚠️ Max updates reached, falling back to reload');
          window.location.reload();
        }
      }
    } catch (e) {
      console.error('Instant update error:', e);
    }
  };
  
  ws.onerror = function(error) {
    console.log('❌ Instant UI updater WebSocket error:', error);
  };
  
  ws.onclose = function() {
    console.log('🔌 Instant UI updater disconnected');
  };
  
  // Apply UI changes to the DOM
  function applyUIChanges(changes) {
    if (!changes || !Array.isArray(changes)) return;
    
    changes.forEach(change => {
      try {
        switch (change.action) {
          case 'update_text':
            updateElementText(change.selector, change.text);
            break;
          case 'update_style':
            updateElementStyle(change.selector, change.style);
            break;
          case 'update_attribute':
            updateElementAttribute(change.selector, change.attribute, change.value);
            break;
          case 'replace_element':
            replaceElement(change.selector, change.html);
            break;
          case 'add_element':
            addElement(change.parent, change.html, change.position);
            break;
          case 'remove_element':
            removeElement(change.selector);
            break;
          case 'update_flutter_widget':
            updateFlutterWidget(change.widgetId, change.properties);
            break;
        }
      } catch (e) {
        console.error('Failed to apply change:', change, e);
      }
    });
  }
  
  // Update element text content
  function updateElementText(selector, text) {
    const element = document.querySelector(selector);
    if (element) {
      element.textContent = text;
    }
  }
  
  // Update element styles
  function updateElementStyle(selector, style) {
    const element = document.querySelector(selector);
    if (element && style) {
      Object.assign(element.style, style);
    }
  }
  
  // Update element attributes
  function updateElementAttribute(selector, attribute, value) {
    const element = document.querySelector(selector);
    if (element) {
      element.setAttribute(attribute, value);
    }
  }
  
  // Replace element content
  function replaceElement(selector, html) {
    const element = document.querySelector(selector);
    if (element) {
      element.innerHTML = html;
    }
  }
  
  // Add new element
  function addElement(parentSelector, html, position = 'append') {
    const parent = document.querySelector(parentSelector);
    if (parent) {
      const tempDiv = document.createElement('div');
      tempDiv.innerHTML = html;
      const newElement = tempDiv.firstElementChild;
      
      if (position === 'prepend') {
        parent.insertBefore(newElement, parent.firstChild);
      } else {
        parent.appendChild(newElement);
      }
    }
  }
  
  // Remove element
  function removeElement(selector) {
    const element = document.querySelector(selector);
    if (element) {
      element.remove();
    }
  }
  
  // Update Flutter widget (if Flutter is available)
  function updateFlutterWidget(widgetId, properties) {
    if (window.flutter_inappwebview) {
      // For Flutter WebView
      window.flutter_inappwebview.callHandler('updateWidget', widgetId, properties);
    } else if (window.flutter_web_optimizer) {
      // For Flutter Web Optimizer
      window.flutter_web_optimizer.updateWidget(widgetId, properties);
    } else {
      // Fallback: try to find and update widget manually
      const widgetElement = document.querySelector('[data-flutter-widget-id="' + widgetId + '"]');
      if (widgetElement && properties) {
        Object.assign(widgetElement.dataset, properties);
        // Trigger a custom event for Flutter to pick up
        widgetElement.dispatchEvent(new CustomEvent('flutter-widget-update', {
          detail: { widgetId, properties }
        }));
      }
    }
  }
  
  // Expose functions for manual control
  window.flutsimInstantUI = {
    enable: () => { updateEnabled = true; },
    disable: () => { updateEnabled = false; },
    update: (changes) => { applyUIChanges(changes); },
    resetCount: () => { updateCount = 0; }
  };
})();
</script>
''';

  /// Inject instant update script into HTML
  static String injectInstantUpdateScript(String html) {
    if (html.contains('</body>')) {
      return html.replaceFirst('</body>', '$_instantUpdateScript</body>');
    }
    return html + _instantUpdateScript;
  }

  /// Create a text update change
  static Map<String, dynamic> createTextUpdate(String selector, String text) {
    return {
      'action': 'update_text',
      'selector': selector,
      'text': text,
    };
  }

  /// Create a style update change
  static Map<String, dynamic> createStyleUpdate(
      String selector, Map<String, String> style) {
    return {
      'action': 'update_style',
      'selector': selector,
      'style': style,
    };
  }

  /// Create an attribute update change
  static Map<String, dynamic> createAttributeUpdate(
      String selector, String attribute, String value) {
    return {
      'action': 'update_attribute',
      'selector': selector,
      'attribute': attribute,
      'value': value,
    };
  }

  /// Create an element replacement change
  static Map<String, dynamic> createElementReplace(
      String selector, String html) {
    return {
      'action': 'replace_element',
      'selector': selector,
      'html': html,
    };
  }

  /// Create a Flutter widget update change
  static Map<String, dynamic> createFlutterWidgetUpdate(
      String widgetId, Map<String, dynamic> properties) {
    return {
      'action': 'update_flutter_widget',
      'widgetId': widgetId,
      'properties': properties,
    };
  }

  /// Send instant update signal to connected browsers
  static String createInstantUpdateMessage(List<Map<String, dynamic>> changes) {
    return jsonEncode({
      'type': 'instant_update',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'changes': changes,
    });
  }
}

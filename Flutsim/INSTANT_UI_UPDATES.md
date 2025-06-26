# Instant UI Updates

Flutsim now includes an advanced instant UI update system that can modify the DOM directly without any page reload. This system provides true instant visual feedback for your changes.

## Features

### ⚡ **Instant DOM Manipulation**

- **No Page Reload**: Changes appear instantly without refreshing
- **DOM Updates**: Direct manipulation of HTML elements
- **Style Changes**: Update CSS properties in real-time
- **Text Updates**: Change text content instantly
- **Element Replacement**: Replace entire elements with new HTML

### 🎯 **Precise Targeting**

- **CSS Selectors**: Target elements using any CSS selector
- **Multiple Elements**: Update multiple elements simultaneously
- **Flutter Widgets**: Special support for Flutter widget updates
- **Conditional Updates**: Apply changes based on conditions

### 🛡️ **Safety & Performance**

- **Update Limits**: Prevents infinite update loops
- **Error Handling**: Graceful fallback to page reload
- **Performance Optimized**: Minimal overhead for updates
- **Connection Recovery**: Automatic reconnection handling

## How It Works

### 1. **Instant UI Update Server**

The system runs a dedicated WebSocket server on port 8085 that:

- Accepts browser connections
- Sends UI update commands when files change
- Manages multiple browser connections

### 2. **Browser Integration**

Each browser page includes a JavaScript script that:

- Connects to the instant UI update server
- Listens for update commands
- Applies changes directly to the DOM

### 3. **Update Types**

The system supports multiple types of updates:

- **Text Updates**: Change element text content
- **Style Updates**: Modify CSS properties
- **Attribute Updates**: Change HTML attributes
- **Element Replacement**: Replace entire elements
- **Flutter Widget Updates**: Special Flutter integration

## Configuration

### Enable/Disable Instant UI Updates

```dart
// In config.dart
static const bool enableInstantUIUpdates = true; // Set to false to disable
```

### Instant UI Update Port

```dart
// In config.dart
static const int instantUIPort = 8085; // Change if needed
```

## Usage

### **Fast Development Mode**

```bash
flutsim run
```

- Hot reload + instant UI updates enabled
- Changes appear instantly in browser
- No page refresh needed

### **Build Mode**

```bash
flutsim build
```

- Full rebuilds with instant UI updates
- DOM changes applied after each build

## Browser Console Commands

You can control instant UI updates from the browser console:

```javascript
// Enable instant UI updates
window.flutsimInstantUI.enable();

// Disable instant UI updates
window.flutsimInstantUI.disable();

// Manually apply changes
window.flutsimInstantUI.update([
  {
    action: "update_text",
    selector: ".my-element",
    text: "New text content",
  },
]);

// Reset update counter
window.flutsimInstantUI.resetCount();
```

## Update Types

### **Text Updates**

```javascript
{
  action: 'update_text',
  selector: '.title',
  text: 'New Title'
}
```

### **Style Updates**

```javascript
{
  action: 'update_style',
  selector: '.button',
  style: {
    backgroundColor: 'red',
    color: 'white',
    fontSize: '16px'
  }
}
```

### **Attribute Updates**

```javascript
{
  action: 'update_attribute',
  selector: 'img',
  attribute: 'src',
  value: 'new-image.jpg'
}
```

### **Element Replacement**

```javascript
{
  action: 'replace_element',
  selector: '.content',
  html: '<div class="new-content">Updated content</div>'
}
```

### **Flutter Widget Updates**

```javascript
{
  action: 'update_flutter_widget',
  widgetId: 'my-widget',
  properties: {
    text: 'New widget text',
    color: 'blue',
    size: 24
  }
}
```

## Technical Details

### Port Usage

- **8080**: Main development server (proxy in fast mode)
- **8083**: Flutter development server (fast mode only)
- **8082**: Hot reload server (instant updates)
- **8084**: Auto reload server (browser refresh)
- **8085**: Instant UI update server (DOM manipulation)

### WebSocket Protocol

```json
{
  "type": "instant_update",
  "timestamp": 1234567890,
  "changes": [
    {
      "action": "update_text",
      "selector": ".element",
      "text": "New text"
    }
  ]
}
```

### Browser Script Injection

The instant UI update script is automatically injected into HTML responses:

- Build mode: Injected by the main server
- Fast mode: Injected by the proxy server

## Advanced Features

### **Multiple Changes**

Send multiple updates in a single message:

```javascript
[
  {
    action: "update_text",
    selector: ".title",
    text: "New Title",
  },
  {
    action: "update_style",
    selector: ".button",
    style: { backgroundColor: "blue" },
  },
  {
    action: "update_attribute",
    selector: "img",
    attribute: "src",
    value: "new-image.jpg",
  },
];
```

### **Flutter Integration**

Special support for Flutter widgets:

```javascript
{
  action: 'update_flutter_widget',
  widgetId: 'counter-widget',
  properties: {
    count: 42,
    color: 'green',
    size: 'large'
  }
}
```

### **Conditional Updates**

Apply updates based on conditions:

```javascript
// Only update if element exists
if (document.querySelector(".my-element")) {
  window.flutsimInstantUI.update([
    {
      action: "update_text",
      selector: ".my-element",
      text: "Updated text",
    },
  ]);
}
```

## Performance Considerations

### **Memory Usage**

- Each browser connection uses minimal memory
- Update commands are lightweight JSON messages
- No persistent storage required

### **Network Traffic**

- WebSocket connections are efficient
- Update messages are small and compressed
- Minimal bandwidth usage

### **CPU Usage**

- DOM manipulation is fast and efficient
- Update batching reduces CPU overhead
- Smart update limiting prevents performance issues

## Integration with Other Features

### **Hot Reload Compatibility**

- Instant UI updates work alongside hot reload
- Both systems can be enabled simultaneously
- Hot reload for Flutter state, UI updates for DOM

### **Auto Reload Compatibility**

- Instant UI updates can fall back to auto reload
- Automatic fallback when updates fail
- Graceful degradation for complex changes

### **QR Code Integration**

- QR codes work with instant UI updates
- Mobile devices get instant UI functionality
- Cross-platform compatibility

## Troubleshooting

### **Updates Not Appearing**

1. Check browser console for connection errors
2. Verify instant UI updates are enabled in config
3. Check if port 8085 is available
4. Try manually triggering updates from console

### **Performance Issues**

1. Reduce update frequency
2. Use more specific selectors
3. Batch multiple updates together
4. Check for infinite update loops

### **Flutter Widget Issues**

1. Ensure widgets have proper IDs
2. Check Flutter integration setup
3. Verify widget properties are correct
4. Use fallback DOM manipulation

## Examples

### **Basic Text Update**

```javascript
// Update a title element
window.flutsimInstantUI.update([
  {
    action: "update_text",
    selector: "h1",
    text: "Updated Title",
  },
]);
```

### **Style Update**

```javascript
// Change button appearance
window.flutsimInstantUI.update([
  {
    action: "update_style",
    selector: ".primary-button",
    style: {
      backgroundColor: "#007bff",
      color: "white",
      padding: "12px 24px",
      borderRadius: "6px",
    },
  },
]);
```

### **Element Replacement**

```javascript
// Replace entire content section
window.flutsimInstantUI.update([
  {
    action: "replace_element",
    selector: ".content-area",
    html: '<div class="new-content"><h2>New Content</h2><p>This is updated content.</p></div>',
  },
]);
```

### **Multiple Updates**

```javascript
// Update multiple elements at once
window.flutsimInstantUI.update([
  {
    action: "update_text",
    selector: ".title",
    text: "New Title",
  },
  {
    action: "update_style",
    selector: ".subtitle",
    style: { color: "blue" },
  },
  {
    action: "update_attribute",
    selector: "img",
    attribute: "alt",
    value: "Updated image description",
  },
]);
```

This instant UI update system provides the most responsive development experience possible, allowing you to see changes instantly without any page reloads or interruptions to your workflow.

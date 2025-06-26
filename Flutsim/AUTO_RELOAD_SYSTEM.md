# Auto Reload System

Flutsim now includes a comprehensive auto reload system that automatically refreshes your browser when you make changes to your code. This system works in both fast development mode and build mode.

## Features

### 🔄 Automatic Browser Refresh

- **Instant Auto Reload**: Browser automatically refreshes when you save files
- **No Manual Intervention**: No need to press F5 or Ctrl+R
- **Smart Debouncing**: Prevents excessive reloads during rapid file changes
- **Multiple Browser Support**: Works with all connected browsers simultaneously

### ⚡ Dual Mode Support

- **Fast Development Mode**: Uses Flutter's hot reload with auto refresh
- **Build Mode**: Full rebuilds with automatic browser refresh

### 🛡️ Safety Features

- **Reload Limit**: Prevents infinite reload loops (max 100 reloads)
- **Connection Recovery**: Automatically reconnects if connection is lost
- **Error Handling**: Graceful handling of connection errors

## How It Works

### 1. Auto Reload Server

The system runs a dedicated WebSocket server on port 8084 that:

- Accepts browser connections
- Sends reload signals when files change
- Manages multiple browser connections

### 2. Browser Integration

Each browser page includes a JavaScript script that:

- Connects to the auto reload server
- Listens for reload signals
- Automatically refreshes the page when changes are detected

### 3. File Watching

The system monitors your `lib/` directory and:

- Detects file changes with debouncing
- Triggers auto reload for all connected browsers
- Works alongside hot reload for instant updates

## Configuration

### Enable/Disable Auto Reload

```dart
// In config.dart
static const bool enableAutoReload = true; // Set to false to disable
```

### Auto Reload Port

```dart
// In config.dart
static const int autoReloadPort = 8084; // Change if needed
```

### Debounce Delay

```dart
// In config.dart
static const int debounceDelay = 500; // Milliseconds
```

## Usage

### Fast Development Mode

```bash
flutsim run
```

- Starts Flutter development server
- Enables hot reload + auto reload
- Changes appear instantly in browser

### Build Mode

```bash
flutsim build
```

- Full rebuilds with auto reload
- Browser refreshes after each build

## Browser Console Commands

You can control auto reload from the browser console:

```javascript
// Enable auto reload
window.flutsimAutoReload.enable();

// Disable auto reload
window.flutsimAutoReload.disable();

// Manually trigger reload
window.flutsimAutoReload.reload();

// Reset reload counter
window.flutsimAutoReload.resetCount();
```

## Technical Details

### Port Usage

- **8080**: Main development server (proxy in fast mode)
- **8083**: Flutter development server (fast mode only)
- **8082**: Hot reload server (instant updates)
- **8084**: Auto reload server (browser refresh)

### WebSocket Protocol

```json
{
  "type": "auto_reload",
  "timestamp": 1234567890
}
```

### Browser Script Injection

The auto reload script is automatically injected into HTML responses:

- Build mode: Injected by the main server
- Fast mode: Injected by the proxy server

## Troubleshooting

### Browser Not Refreshing

1. Check browser console for connection errors
2. Verify auto reload is enabled in config
3. Check if port 8084 is available
4. Try manually triggering reload from console

### Multiple Reloads

1. Increase debounce delay in config
2. Check for file watcher issues
3. Verify no infinite loops in code

### Connection Issues

1. Check firewall settings
2. Verify network interface selection
3. Try different port if 8084 is blocked

## Performance Considerations

### Memory Usage

- Each browser connection uses minimal memory
- Old connections are automatically cleaned up
- No persistent storage required

### Network Traffic

- WebSocket connections are lightweight
- Reload signals are small JSON messages
- Minimal bandwidth usage

### CPU Usage

- File watching is efficient with debouncing
- WebSocket server has minimal overhead
- No polling required

## Integration with Other Features

### Hot Reload Compatibility

- Auto reload works alongside hot reload
- Both systems can be enabled simultaneously
- Hot reload provides instant updates, auto reload provides full refresh

### Live Reload Compatibility

- Auto reload replaces live reload functionality
- More efficient than polling-based live reload
- Better error handling and recovery

### QR Code Integration

- QR codes point to the correct server URL
- Works with both development and build modes
- Mobile devices get auto reload functionality

## Examples

### Basic Usage

```bash
# Start with auto reload enabled
flutsim run

# Make changes to your code
# Browser automatically refreshes
```

### Custom Configuration

```dart
// config.dart
class FlutsimConfig {
  static const bool enableAutoReload = true;
  static const int autoReloadPort = 8084;
  static const int debounceDelay = 300; // Faster response
}
```

### Browser Control

```javascript
// Disable auto reload temporarily
window.flutsimAutoReload.disable();

// Make changes without auto reload
// ... make changes ...

// Re-enable auto reload
window.flutsimAutoReload.enable();
```

This auto reload system provides a seamless development experience with automatic browser refresh, making your Flutter web development workflow faster and more efficient.

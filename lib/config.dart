/// Configuration for Flutsim development modes
class FlutsimConfig {
  /// Use fast development mode (flutter run) instead of full builds
  /// This provides hot reload and is much faster for development
  static const bool useFastMode = true;

  /// Debounce delay for file changes (milliseconds)
  /// Increase this if you have many rapid file changes
  static const int debounceDelay = 250;

  /// Use HTML renderer for faster builds (only applies to build mode)
  static const bool useHtmlRenderer = true;

  /// Disable icon tree-shaking for faster builds (only applies to build mode)
  static const bool disableIconTreeShaking = true;

  /// Disable Skia for faster builds (only applies to build mode)
  static const bool disableSkia = true;

  /// Development server port (Flutter app)
  static const int port = 8080;

  /// Flutter development server port (for fast mode) - changed to avoid conflicts
  static const int flutterDevPort = 8083;

  /// Unified WebSocket Server (Handles Live, Hot, Auto, Instant, and Errors)
  static const int unifiedWebSocketPort = 8086;

  /// Enable instant hot reload (no page refresh)
  static const bool enableInstantHotReload = true;

  /// Enable auto reload (browser refresh)
  static const bool enableAutoReload = true;

  /// Enable instant UI updates (DOM manipulation)
  static const bool enableInstantUIUpdates = true;
}

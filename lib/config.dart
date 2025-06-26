/// Configuration for Flutsim development modes
class FlutsimConfig {
  /// Use fast development mode (flutter run) instead of full builds
  /// This provides hot reload and is much faster for development
  static const bool useFastMode = true;

  /// Debounce delay for file changes (milliseconds)
  /// Increase this if you have many rapid file changes
  static const int debounceDelay = 500;

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

  /// Live reload server port
  static const int liveReloadPort = 8080;

  /// Hot reload server port for instant updates
  static const int hotReloadPort = 8082;

  /// Auto reload server port for browser refresh
  static const int autoReloadPort = 8084;

  /// Instant UI update server port for DOM manipulation
  static const int instantUIPort = 8085;

  /// Enable instant hot reload (no page refresh)
  static const bool enableInstantHotReload = true;

  /// Enable auto reload (browser refresh)
  static const bool enableAutoReload = true;

  /// Enable instant UI updates (DOM manipulation)
  static const bool enableInstantUIUpdates = true;
}

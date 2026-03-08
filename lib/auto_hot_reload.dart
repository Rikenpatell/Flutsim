import 'dart:io';
import 'dart:async';
import 'package:watcher/watcher.dart';
import 'config.dart';

/// Automatic hot reload system that works with Flutter's development server
class AutoHotReload {
  final String flutterDevPort;
  final String host;
  final DirectoryWatcher watcher;
  Timer? _debounceTimer;
  bool _isReloading = false;

  AutoHotReload({
    required this.flutterDevPort,
    this.host = 'localhost',
  }) : watcher = DirectoryWatcher('lib');

  /// Start automatic hot reload monitoring
  void start() {
    print('🔥 Starting automatic hot reload monitoring...');

    watcher.events.listen((event) {
      _handleFileChange(event);
    });
  }

  /// Handle file changes and trigger hot reload
  void _handleFileChange(WatchEvent event) {
    // Skip if already reloading
    if (_isReloading) {
      print('⏳ Hot reload already in progress, skipping...');
      return;
    }

    // Debounce rapid changes
    _debounceTimer?.cancel();
    _debounceTimer = Timer(Duration(milliseconds: FlutsimConfig.debounceDelay), () {
      _triggerHotReload(event.path);
    });
  }

  /// Trigger hot reload by sending HTTP request to Flutter dev server
  Future<void> _triggerHotReload(String filePath) async {
    print('🔃 Change detected in $filePath');
    print('🔥 Triggering automatic hot reload...');

    _isReloading = true;

    try {
      // Try multiple approaches to trigger hot reload
      bool success = false;

      // Method 1: Try Flutter's hot reload endpoint
      success = await _tryFlutterHotReloadEndpoint();

      // Method 2: If that fails, try to restart the Flutter process
      if (!success) {
        success = await _tryRestartFlutterProcess();
      }

      if (success) {
        print('✅ Hot reload triggered successfully!');
      } else {
        print('⚠️  Hot reload failed, please press "R" manually');
      }
    } catch (e) {
      print('❌ Error triggering hot reload: $e');
    } finally {
      _isReloading = false;
    }
  }

  /// Try to trigger hot reload via Flutter's development server endpoint
  Future<bool> _tryFlutterHotReloadEndpoint() async {
    try {
      final url = 'http://$host:$flutterDevPort/__flutter_web_hot_reload__';

      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(url));

      final response = await request.close();
      client.close();

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Try to restart Flutter process (fallback method)
  Future<bool> _tryRestartFlutterProcess() async {
    try {
      // This is a fallback method - in a real implementation,
      // you would communicate with the Flutter process more directly
      print('🔄 Attempting to restart Flutter process...');

      // For now, we'll just return false to indicate manual intervention is needed
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Stop monitoring
  void stop() {
    _debounceTimer?.cancel();
    print('🔥 Stopped automatic hot reload monitoring');
  }
}

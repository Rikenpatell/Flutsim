import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';
import 'package:path/path.dart' as path;
import 'package:watcher/watcher.dart';
import 'websocket_server.dart';
import 'dart:async';
import 'config.dart';
import 'hot_reload_server.dart';
import 'hot_reload_manager.dart';
import 'auto_reload_server.dart';
import 'browser_auto_reload.dart';
import 'flutter_dev_proxy.dart';
import 'instant_ui_server.dart';
import 'instant_ui_updater.dart';
import 'qr_generator.dart';

/// Check if a port is available
Future<bool> isPortAvailable(int port) async {
  try {
    final server = await ServerSocket.bind('0.0.0.0', port);
    await server.close();
    return true;
  } catch (e) {
    return false;
  }
}

/// Find an available port starting from the given port
Future<int> findAvailablePort(int startPort) async {
  int port = startPort;
  while (!await isPortAvailable(port)) {
    port++;
    if (port > startPort + 10) {
      throw Exception(
          'No available ports found in range $startPort-${startPort + 10}');
    }
  }
  return port;
}

/// Get Flutter installation path
String? getFlutterPath() {
  // First check if flutter is available using PowerShell's Get-Command
  try {
    final result = Process.runSync('powershell', [
      '-Command',
      'Get-Command flutter | Select-Object -ExpandProperty Source'
    ]);
    if (result.exitCode == 0) {
      final flutterPath = result.stdout.toString().trim();
      if (flutterPath.isNotEmpty &&
          flutterPath !=
              'Get-Command : The term \'flutter\' is not recognized') {
        return flutterPath;
      }
    }
  } catch (e) {
    // Ignore errors and continue with path checking
  }

  // Common Flutter installation paths on Windows
  final possiblePaths = [
    'C:\\flutter\\bin\\flutter.bat',
    'C:\\src\\flutter\\bin\\flutter.bat',
    'C:\\Users\\${Platform.environment['USERNAME']}\\flutter\\bin\\flutter.bat',
    'C:\\Users\\${Platform.environment['USERNAME']}\\Documents\\flutter\\bin\\flutter.bat',
    'C:\\Users\\${Platform.environment['USERNAME']}\\Desktop\\flutter\\bin\\flutter.bat',
    'C:\\Users\\${Platform.environment['USERNAME']}\\dev\\flutter\\bin\\flutter.bat',
    'C:\\Users\\${Platform.environment['USERNAME']}\\AppData\\Local\\flutter\\bin\\flutter.bat',
    'C:\\Program Files\\flutter\\bin\\flutter.bat',
    'C:\\Program Files (x86)\\flutter\\bin\\flutter.bat',
  ];

  for (final path in possiblePaths) {
    if (File(path).existsSync()) {
      return path;
    }
  }
  return null;
}

Future<void> runFlutsimPreview() async {
  final port = FlutsimConfig.port;
  final buildDir = Directory('build/web');
  final liveReload = LiveReloadServer();
  final hotReload = HotReloadServer();
  final autoReload = AutoReloadServer();
  final instantUI = InstantUIServer();

  await liveReload.start();

  // Start hot reload server if enabled
  if (FlutsimConfig.enableInstantHotReload) {
    await hotReload.start();
  }

  // Start auto reload server if enabled
  if (FlutsimConfig.enableAutoReload) {
    await autoReload.start();
  }

  // Start instant UI update server if enabled
  if (FlutsimConfig.enableInstantUIUpdates) {
    await instantUI.start();
  }

  // Check if we should use fast development mode
  if (FlutsimConfig.useFastMode) {
    print('🚀 Starting Flutter in fast development mode...');
    await _startFastDevelopmentMode(
        port, liveReload, hotReload, autoReload, instantUI);
    return;
  }

  // Step 1: Build Flutter Web with development optimizations
  if (!buildDir.existsSync()) {
    print('🔧 Building Flutter web (development mode)...');

    // Get the Flutter path to use full path instead of relying on PATH
    final flutterPath = getFlutterPath();
    final flutterCommand = flutterPath ?? 'flutter';

    // Build flags based on configuration
    final buildFlags = ['build', 'web', '--release'];

    if (FlutsimConfig.useHtmlRenderer) {
      buildFlags.addAll(['--web-renderer', 'html']);
    }

    if (FlutsimConfig.disableSkia) {
      buildFlags.add('--dart-define=FLUTTER_WEB_USE_SKIA=false');
    }

    if (FlutsimConfig.disableIconTreeShaking) {
      buildFlags.add('--no-tree-shake-icons');
    }

    // Use development-optimized build flags
    final buildProcess = await Process.start(
      flutterCommand,
      buildFlags,
      mode: ProcessStartMode.inheritStdio,
    );
    final exitCode = await buildProcess.exitCode;

    if (exitCode != 0) {
      print('❌ Web build failed.');
      return;
    }
  } else {
    print('✅ Web build already exists.');
  }

  // Step 2: Get IP address and show available interfaces
  final ip = await getLocalIp();
  final url = 'http://$ip:$port';

  // Show all available interfaces for debugging
  await _showAvailableInterfaces();

  // Step 3: Serve Web Folder with live reload injection
  final handler = createStaticHandler(
    path.absolute(buildDir.path),
    defaultDocument: 'index.html',
  );

  // Create a middleware to inject live reload script
  Future<Response> liveReloadHandler(Request request) async {
    final response = await handler(request);

    // Only inject script for HTML files
    if (request.url.path.endsWith('.html') || request.url.path.isEmpty) {
      final body = await response.readAsString();

      // Inject live reload script before closing body tag
      final liveReloadScript = '''
<script>
// Live Reload Client
(function() {
  const ws = new WebSocket('ws://' + window.location.hostname + ':${FlutsimConfig.liveReloadPort}');
  
  ws.onopen = function() {
    console.log('🔌 Connected to live reload server');
  };
  
  ws.onmessage = function(event) {
    const data = JSON.parse(event.data);
    if (data.type === 'reload') {
      console.log('🔄 Live reload triggered');
      window.location.reload();
    }
  };
  
  ws.onerror = function(error) {
    console.log('❌ WebSocket error:', error);
  };
  
  ws.onclose = function() {
    console.log('🔌 Disconnected from live reload server');
    // Try to reconnect after 2 seconds
    setTimeout(function() {
      window.location.reload();
    }, 2000);
  };
})();
</script>
''';

      // Inject hot reload script if enabled
      String modifiedBody =
          body.replaceFirst('</body>', '$liveReloadScript</body>');

      if (FlutsimConfig.enableInstantHotReload) {
        modifiedBody = HotReloadManager.injectHotReloadScript(modifiedBody);
      }

      if (FlutsimConfig.enableAutoReload) {
        modifiedBody = BrowserAutoReload.injectAutoReloadScript(modifiedBody);
      }

      if (FlutsimConfig.enableInstantUIUpdates) {
        modifiedBody = InstantUIUpdater.injectInstantUpdateScript(modifiedBody);
      }

      return Response.ok(
        modifiedBody,
        headers: response.headers,
      );
    }

    return response;
  }

  await shelf_io.serve(liveReloadHandler, InternetAddress.anyIPv4, port);

  print('✅ Local server started at: $url');
  print('\n📱 Open this URL on your device: $url');
  print('🔄 Press Ctrl+C to stop the server');

  if (FlutsimConfig.enableInstantHotReload) {
    print('🔥 Instant hot reload enabled - changes appear immediately!');
  }

  if (FlutsimConfig.enableAutoReload) {
    print('🔄 Auto reload enabled - browser will refresh automatically!');
  }

  if (FlutsimConfig.enableInstantUIUpdates) {
    print('⚡ Instant UI updates enabled - DOM changes without reload!');
  }

  // Generate and display QR code
  await generateAndDisplayQRCode(url);

  // Get the Flutter path
  final flutterPath = getFlutterPath();
  final flutterCommand = flutterPath ?? 'flutter';

  // Start Flutter in development mode with web-server and hot reload
  print('🚀 Starting Flutter development server with hot reload...');

  // Start Flutter process with stdin/stdout communication
  final flutterProcess = await Process.start(
    flutterCommand,
    [
      'run',
      '-d', 'web-server',
      '--web-port', port.toString(),
      '--web-hostname', '0.0.0.0',
      '--hot', // Enable hot reload
      '--debug', // Use debug mode for faster hot reload
    ],
    mode: ProcessStartMode.normal,
  );

  // Pipe stdout and stderr to this process
  stdout.addStream(flutterProcess.stdout);
  stderr.addStream(flutterProcess.stderr);

  // Start file watcher for automatic hot reload
  final watcher = DirectoryWatcher('lib');
  print('👀 Watching lib/ for changes...');

  Timer? debounceTimer;
  bool isHotReloading = false;

  watcher.events.listen((event) async {
    // Skip if already hot reloading
    if (isHotReloading) {
      print('⏳ Hot reload already in progress, skipping...');
      return;
    }

    // Debounce rapid changes
    debounceTimer?.cancel();
    debounceTimer =
        Timer(Duration(milliseconds: FlutsimConfig.debounceDelay), () async {
      print('🔃 Change detected in ${event.path}');
      print('🔥 Triggering automatic hot reload...');

      isHotReloading = true;
      try {
        // Trigger instant hot reload if enabled
        if (FlutsimConfig.enableInstantHotReload) {
          hotReload.triggerInstantHotReload();
        }

        // Trigger auto reload if enabled
        if (FlutsimConfig.enableAutoReload) {
          autoReload.triggerAutoReload();
        }

        // Trigger instant UI updates if enabled
        if (FlutsimConfig.enableInstantUIUpdates) {
          instantUI.sendInstantUIUpdate([
            {
              'action': 'update_text',
              'selector': 'body',
              'text': 'Updated at ${DateTime.now().toString()}',
            }
          ]);
        }

        // Send 'r' to flutter process stdin
        flutterProcess.stdin.write('r\n');
        print('✅ Hot reload triggered automatically!');
      } catch (e) {
        print('❌ Failed to trigger hot reload: $e');
      } finally {
        isHotReloading = false;
      }
    });
  });

  // Wait for the process to complete
  await flutterProcess.exitCode;
}

/// Start Flutter in fast development mode using flutter run
Future<void> _startFastDevelopmentMode(
    int port,
    LiveReloadServer liveReload,
    HotReloadServer hotReload,
    AutoReloadServer autoReload,
    InstantUIServer instantUI) async {
  final ip = await getLocalIp();

  // Find an available port for Flutter development server
  final flutterPort = await findAvailablePort(FlutsimConfig.flutterDevPort);
  final proxyPort = await findAvailablePort(FlutsimConfig.port);

  // Create proxy server
  final proxy = FlutterDevProxy(
    proxyPort: proxyPort,
    flutterPort: flutterPort,
  );

  await proxy.start();

  final url = 'http://$ip:$proxyPort';

  print('🔍 Checking port availability...');
  print('✅ Using port $flutterPort for Flutter development server');
  print('✅ Using port $proxyPort for proxy server');

  // Show all available interfaces for debugging
  await _showAvailableInterfaces();

  print('✅ Fast development server will be available at: $url');
  print('\n📱 Open this URL on your device: $url');
  print('🔄 Press Ctrl+C to stop the server');
  print('🔥 Hot reload enabled - changes will appear instantly!');

  if (FlutsimConfig.enableInstantHotReload) {
    print('⚡ Instant hot reload enabled - no page refresh needed!');
  }

  if (FlutsimConfig.enableAutoReload) {
    print('🔄 Auto reload enabled - browser will refresh automatically!');
  }

  if (FlutsimConfig.enableInstantUIUpdates) {
    print('⚡ Instant UI updates enabled - DOM changes without reload!');
  }

  // Generate and display QR code
  await generateAndDisplayQRCode(url);

  // Get the Flutter path
  final flutterPath = getFlutterPath();
  final flutterCommand = flutterPath ?? 'flutter';

  // Start Flutter in development mode with web-server and hot reload
  print('🚀 Starting Flutter development server with hot reload...');

  // Start Flutter process with stdin/stdout communication
  final flutterProcess = await Process.start(
    flutterCommand,
    [
      'run',
      '-d', 'web-server',
      '--web-port', flutterPort.toString(),
      '--web-hostname', '0.0.0.0',
      '--hot', // Enable hot reload
      '--debug', // Use debug mode for faster hot reload
    ],
    mode: ProcessStartMode.normal,
  );

  // Pipe stdout and stderr to this process
  stdout.addStream(flutterProcess.stdout);
  stderr.addStream(flutterProcess.stderr);

  // Start file watcher for automatic hot reload
  final watcher = DirectoryWatcher('lib');
  print('👀 Watching lib/ for changes...');

  Timer? debounceTimer;
  bool isHotReloading = false;

  watcher.events.listen((event) async {
    // Skip if already hot reloading
    if (isHotReloading) {
      print('⏳ Hot reload already in progress, skipping...');
      return;
    }

    // Debounce rapid changes
    debounceTimer?.cancel();
    debounceTimer =
        Timer(Duration(milliseconds: FlutsimConfig.debounceDelay), () async {
      print('🔃 Change detected in ${event.path}');
      print('🔥 Triggering automatic hot reload...');

      isHotReloading = true;
      try {
        // Trigger instant hot reload if enabled
        if (FlutsimConfig.enableInstantHotReload) {
          hotReload.triggerInstantHotReload();
        }

        // Trigger auto reload if enabled
        if (FlutsimConfig.enableAutoReload) {
          autoReload.triggerAutoReload();
        }

        // Trigger instant UI updates if enabled
        if (FlutsimConfig.enableInstantUIUpdates) {
          instantUI.sendInstantUIUpdate([
            {
              'action': 'update_text',
              'selector': 'body',
              'text': 'Updated at ${DateTime.now().toString()}',
            }
          ]);
        }

        // Send 'r' to flutter process stdin
        flutterProcess.stdin.write('r\n');
        print('✅ Hot reload triggered automatically!');
      } catch (e) {
        print('❌ Failed to trigger hot reload: $e');
      } finally {
        isHotReloading = false;
      }
    });
  });

  // Wait for the process to complete
  await flutterProcess.exitCode;
}

/// Show all available network interfaces for debugging
Future<void> _showAvailableInterfaces() async {
  print('\n📡 Available network interfaces:');
  print('┌─────────────────────────────────────┐');

  final interfaces = await NetworkInterface.list(
    includeLoopback: false,
    type: InternetAddressType.IPv4,
  );

  for (var iface in interfaces) {
    for (var addr in iface.addresses) {
      if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
        final isSelected = addr.address == await getLocalIp();
        final indicator = isSelected ? '✅' : '  ';
        print('$indicator ${iface.name}: ${addr.address}');
      }
    }
  }

  print('└─────────────────────────────────────┘');
  print('💡 If the selected IP doesn\'t work, try one of the other IPs above');
}

Future<String> getLocalIp() async {
  final interfaces = await NetworkInterface.list(
    includeLoopback: false,
    type: InternetAddressType.IPv4,
  );

  // Priority order for network interfaces
  // 1. WiFi interfaces (usually work best for mobile access)
  // 2. Ethernet interfaces
  // 3. Other interfaces

  // First, try to find WiFi interfaces
  for (var iface in interfaces) {
    // Look for common WiFi interface names
    if (iface.name.toLowerCase().contains('wifi') ||
        iface.name.toLowerCase().contains('wireless') ||
        iface.name.toLowerCase().contains('wi-fi') ||
        iface.name.toLowerCase().contains('802.11') ||
        iface.name.toLowerCase().contains('wlan')) {
      for (var addr in iface.addresses) {
        if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
          print('📡 Found WiFi interface: ${iface.name} - ${addr.address}');
          return addr.address;
        }
      }
    }
  }

  // If no WiFi found, try Ethernet interfaces
  for (var iface in interfaces) {
    if (iface.name.toLowerCase().contains('ethernet') ||
        iface.name.toLowerCase().contains('lan') ||
        iface.name.toLowerCase().contains('local area connection')) {
      for (var addr in iface.addresses) {
        if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
          print('📡 Found Ethernet interface: ${iface.name} - ${addr.address}');
          return addr.address;
        }
      }
    }
  }

  // Fallback to any non-loopback IPv4 address
  for (var iface in interfaces) {
    for (var addr in iface.addresses) {
      if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
        print('📡 Found interface: ${iface.name} - ${addr.address}');
        return addr.address;
      }
    }
  }

  return '127.0.0.1'; // fallback
}

/// Generate and display QR code for the local server URL
Future<void> generateAndDisplayQRCode(String url) async {
  try {
    print('\n📱 QR Code for easy mobile access:');
    print('┌─────────────────────────────────────┐');

    // Generate QR code using the QRGenerator class with smaller size
    QRGenerator.printQRCodeToTerminal(url, size: 2);

    print('└─────────────────────────────────────┘');
    print('📱 Scan this QR code with your mobile device to access the app');
    print('🔗 Or manually visit: $url');
  } catch (e) {
    print('⚠️  Could not generate QR code: $e');
    print('🔗 Please manually visit: $url');
  }
}

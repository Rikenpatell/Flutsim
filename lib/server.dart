import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';
import 'package:path/path.dart' as path;
import 'package:watcher/watcher.dart';
import 'dart:async';
import 'dart:convert';
import 'config.dart';
import 'flutter_dev_proxy.dart';
import 'unified_websocket_server.dart';
import 'flutsim_client.dart';
import 'qr_generator.dart';

const String ansiReset = '\x1B[0m';
const String ansiGreen = '\x1B[32m';
const String ansiRed = '\x1B[31m';
const String ansiBlue = '\x1B[34m';
const String ansiYellow = '\x1B[33m';

void openBrowser(String url) {
  try {
    if (Platform.isMacOS) {
      Process.run('open', [url]);
    } else if (Platform.isWindows) {
      Process.run('start', [url], runInShell: true);
    } else if (Platform.isLinux) {
      Process.run('xdg-open', [url]);
    }
  } catch (e) {
    print('$ansiRed⚠️ Failed to open browser: $e$ansiReset');
  }
}

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
  final unifiedServer = UnifiedWebSocketServer();
  await unifiedServer.start();

  // Check if we should use fast development mode
  if (FlutsimConfig.useFastMode) {
    print('$ansiBlue🚀 Starting Flutter in fast development mode...$ansiReset');
    await _startFastDevelopmentMode(port, unifiedServer);
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

  // Step 2: Get IP address
  final ip = await getLocalIp();
  final url = 'http://$ip:$port';

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

      // Inject unified FlutSim client script
      String modifiedBody = FlutSimClient.injectScript(body, unifiedServer.port);

      return Response.ok(
        modifiedBody,
        headers: response.headers,
      );
    }

    return response;
  }

  await shelf_io.serve(liveReloadHandler, InternetAddress.anyIPv4, port);

  print('\n$ansiGreen🚀 Flutter Web Server: $url$ansiReset\n');
  
  // Auto-open browser for standard preview mode
  openBrowser(url);

  // Generate and display QR code
  await generateAndDisplayQRCode(url);

  // Get the Flutter path
  final flutterPath = getFlutterPath();
  final flutterCommand = flutterPath ?? 'flutter';
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

  String? devToolsUrl;

  // Pipe stdout and stderr to this process and intercept errors
  flutterProcess.stdout.transform(utf8.decoder).listen((data) {
    stdout.write(data);
    
    // Capture DevTools URL
    if (data.contains('DevTools debugger')) {
      final match = RegExp(r'http://127\.0\.0\.1:[0-9]+[^ \n\r]*').firstMatch(data);
      if (match != null) {
        devToolsUrl = match.group(0);
      }
    }
    
    // Check for compilation or generic errors to overlay in browser
    if (data.contains('Error: ') || data.contains('Exception: ') || data.contains('Failed to compile')) {
      unifiedServer.sendError(data);
    } else if (data.contains('Reloaded ') || data.contains('Restarted ')) {
      unifiedServer.clearError(); // Wipe the overlay on successful reload
    }
  });

  flutterProcess.stderr.transform(utf8.decoder).listen((data) {
    stderr.write(data);
    if (data.contains('Error: ') || data.contains('Exception: ')) {
      unifiedServer.sendError(data);
    }
  });

  // Start Terminal UI (TUI) Listener
  if (stdin.hasTerminal) {
    stdin.echoMode = false;
    stdin.lineMode = false;
    
    print('\n$ansiBlue🎮 Terminal UI active:$ansiReset');
    print('  [r] Hot Reload  |  [R] Hot Restart');
    print('  [d] DevTools    |  [c] Clear');
    print('  [q] Quit        |  [h] Help / QR');

    stdin.listen((List<int> codes) {
      final key = utf8.decode(codes);
      
      switch (key) {
        case 'r':
          print('\n$ansiYellow🔥 Manual Hot Reload...$ansiReset');
          flutterProcess.stdin.write('r\n');
          unifiedServer.triggerHotReload();
          break;
        case 'R':
          print('\n$ansiYellow💥 Manual Hot Restart...$ansiReset');
          flutterProcess.stdin.write('R\n');
          unifiedServer.triggerAutoReload();
          break;
        case 'd':
          if (devToolsUrl != null) {
            print('\n$ansiBlue🛠 Opening Dart DevTools...$ansiReset');
            openBrowser(devToolsUrl!);
          } else {
            print('\n$ansiYellow⚠️ DevTools URL not yet available.$ansiReset');
          }
          break;
        case 'c':
          print('\x1B[2J\x1B[0;0H'); // Clear terminal
          break;
        case 'q':
        case '\x03': // Ctrl+C
          print('\n$ansiGreen👋 Exiting FlutSim...$ansiReset');
          flutterProcess.kill();
          exit(0);
        case 'h':
          generateAndDisplayQRCode(url);
          break;
      }
    });
  }

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
          unifiedServer.triggerHotReload();
        }

        // Trigger auto reload if enabled and instant hot reload is disabled
        if (FlutsimConfig.enableAutoReload && !FlutsimConfig.enableInstantHotReload) {
          unifiedServer.triggerAutoReload();
        }

        // Trigger instant UI updates if enabled
        if (FlutsimConfig.enableInstantUIUpdates) {
          unifiedServer.sendInstantUIUpdate([
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
        
        // Cooldown to ensure flutter finishes hot reloading before allowing another
        await Future.delayed(const Duration(milliseconds: 1500));
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
    UnifiedWebSocketServer unifiedServer) async {
  final ip = await getLocalIp();

  // Find an available port for Flutter development server
  final flutterPort = await findAvailablePort(FlutsimConfig.flutterDevPort);
  final proxyPort = await findAvailablePort(FlutsimConfig.port);

  // Create proxy server
  final proxy = FlutterDevProxy(
    proxyPort: proxyPort,
    flutterPort: flutterPort,
    unifiedPort: unifiedServer.port,
  );

  await proxy.start();

  final url = 'http://$ip:$proxyPort';

  print('\n$ansiGreen🚀 Flutter Development Server: http://$ip:$flutterPort$ansiReset');
  print('$ansiBlue🔄 FlutSim Proxy Server (with Hot Reload): $url$ansiReset\n');

  // Generate and display QR code (using Flutter Dev Server URL as requested)
  await generateAndDisplayQRCode('http://$ip:$flutterPort');

  // Get the Flutter path
  final flutterPath = getFlutterPath();
  final flutterCommand = flutterPath ?? 'flutter';

  // Start Flutter in development mode with web-server and hot reload
  print('$ansiBlue🚀 Starting Flutter development server with hot reload...$ansiReset');

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

  String? devToolsUrl;

  bool hasOpenedBrowser = false;

  // Pipe stdout and stderr to this process and intercept errors
  flutterProcess.stdout.transform(utf8.decoder).listen((data) {
    stdout.write(data);
    
    // Open browser when flutter is ready
    if (!hasOpenedBrowser && (data.contains('is being served at') || data.contains('To hot restart'))) {
      print('\n$ansiBlue🌐 Flutter is ready! Opening browser automatically...$ansiReset');
      openBrowser(url);
      hasOpenedBrowser = true;
    }
    
    // Capture DevTools URL
    if (data.contains('DevTools debugger')) {
      final match = RegExp(r'http://127\.0\.0\.1:[0-9]+[^ \n\r]*').firstMatch(data);
      if (match != null) {
        devToolsUrl = match.group(0);
      }
    }
    
    // Check for compilation or generic errors to overlay in browser
    if (data.contains('Error: ') || data.contains('Exception: ') || data.contains('Failed to compile')) {
      unifiedServer.sendError(data);
    } else if (data.contains('Reloaded ') || data.contains('Restarted ')) {
      unifiedServer.clearError(); // Wipe the overlay on successful reload
    }
  });

  flutterProcess.stderr.transform(utf8.decoder).listen((data) {
    stderr.write(data);
    if (data.contains('Error: ') || data.contains('Exception: ')) {
      unifiedServer.sendError(data);
    }
  });

  // Start Terminal UI (TUI) Listener
  if (stdin.hasTerminal) {
    stdin.echoMode = false;
    stdin.lineMode = false;
    
    print('\n$ansiBlue🎮 Terminal UI active:$ansiReset');
    print('  [r] Hot Reload  |  [R] Hot Restart');
    print('  [d] DevTools    |  [c] Clear');
    print('  [q] Quit        |  [h] Help / QR');

    stdin.listen((List<int> codes) {
      final key = utf8.decode(codes);
      
      switch (key) {
        case 'r':
          print('\n$ansiYellow🔥 Manual Hot Reload...$ansiReset');
          flutterProcess.stdin.write('r\n');
          unifiedServer.triggerHotReload();
          break;
        case 'R':
          print('\n$ansiYellow💥 Manual Hot Restart...$ansiReset');
          flutterProcess.stdin.write('R\n');
          unifiedServer.triggerAutoReload();
          break;
        case 'd':
          if (devToolsUrl != null) {
            print('\n$ansiBlue🛠 Opening Dart DevTools...$ansiReset');
            openBrowser(devToolsUrl!);
          } else {
            print('\n$ansiYellow⚠️ DevTools URL not yet available.$ansiReset');
          }
          break;
        case 'c':
          print('\x1B[2J\x1B[0;0H'); // Clear terminal
          break;
        case 'q':
        case '\x03': // Ctrl+C
          print('\n$ansiGreen👋 Exiting FlutSim...$ansiReset');
          flutterProcess.kill();
          exit(0);
        case 'h':
          generateAndDisplayQRCode(url);
          break;
      }
    });
  }

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
          unifiedServer.triggerHotReload();
        }

        // Trigger auto reload if enabled and instant hot reload is disabled
        if (FlutsimConfig.enableAutoReload && !FlutsimConfig.enableInstantHotReload) {
          unifiedServer.triggerAutoReload();
        }

        // Trigger instant UI updates if enabled
        if (FlutsimConfig.enableInstantUIUpdates) {
          unifiedServer.sendInstantUIUpdate([
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
        
        // Cooldown to ensure flutter finishes hot reloading before allowing another
        await Future.delayed(const Duration(milliseconds: 1500));
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
    // Generate QR code using the QRGenerator class with smaller size
    QRGenerator.printQRCodeToTerminal(url, size: 2);
    print('🔗 Or manually visit: $url');
  } catch (e) {
    print('⚠️  Could not generate QR code: $e');
    print('🔗 Please manually visit: $url');
  }
}

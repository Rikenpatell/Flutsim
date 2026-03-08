import 'dart:io';
import 'package:flutsim/server.dart';

/// Check if Flutter is installed and accessible
Future<bool> isFlutterInstalled() async {
  try {
    final result = await Process.run('flutter', ['--version']);
    return result.exitCode == 0;
  } catch (e) {
    // Try to find Flutter in common paths and use full path
    final flutterPath = getFlutterPath();
    if (flutterPath != null) {
      try {
        final result = await Process.run(flutterPath, ['--version']);
        return result.exitCode == 0;
      } catch (e2) {
        return false;
      }
    }
    return false;
  }
}

/// Get Flutter installation path
String? getFlutterPath() {
  // Common Flutter installation paths on Windows
  final possiblePaths = [
    'C:\\flutter\\bin\\flutter.bat',
    'C:\\src\\flutter\\bin\\flutter.bat',
    'C:\\Users\\${Platform.environment['USERNAME']}\\flutter\\bin\\flutter.bat',
    'C:\\Users\\${Platform.environment['USERNAME']}\\Documents\\flutter\\bin\\flutter.bat',
    'C:\\Users\\${Platform.environment['USERNAME']}\\Desktop\\flutter\\bin\\flutter.bat',
    'C:\\Users\\${Platform.environment['USERNAME']}\\dev\\flutter\\bin\\flutter.bat',
  ];

  for (final path in possiblePaths) {
    if (File(path).existsSync()) {
      return path;
    }
  }
  return null;
}

/// Entrypoint for `flutsim run` command.
Future<void> runFlutsim() async {
  // Check if Flutter is installed
  if (!await isFlutterInstalled()) {
    print('❌ Flutter is not installed or not found in PATH.');

    // Try to find Flutter installation
    final flutterPath = getFlutterPath();
    if (flutterPath != null) {
      print('✅ Found Flutter at: $flutterPath');
      print('💡 You can add this to your PATH or use the full path.');
    } else {
      print('💡 To install Flutter:');
      print(
          '   1. Download from: https://docs.flutter.dev/get-started/install/windows');
      print('   2. Extract to C:\\flutter');
      print('   3. Add C:\\flutter\\bin to your PATH');
    }
    exit(1);
  }

  // Check if we're in a Flutter project directory
  if (!File('pubspec.yaml').existsSync()) {
    // Check if there's a testapp directory nearby
    final testappDir = Directory('testapp');
    if (testappDir.existsSync()) {
      print('📁 Found testapp directory, navigating to it...');
      Directory.current = testappDir;
    } else {
      print('❌ No Flutter project found in current directory.');
      print('💡 Available options:');
      print('   1. Navigate to a Flutter project directory');
      print('   2. Create a new project: flutsim create <project-name>');
      print('   3. Run from a directory with a testapp folder');
      exit(1);
    }
  }

  // Check if pubspec.yaml contains Flutter dependency
  final pubspecContent = File('pubspec.yaml').readAsStringSync();
  if (!pubspecContent.contains('flutter:') &&
      !pubspecContent.contains('sdk: flutter')) {
    print('❌ This does not appear to be a Flutter project.');
    print('💡 Make sure pubspec.yaml contains Flutter dependencies.');
    exit(1);
  }

  try {
    await runFlutsimPreview();
  } catch (e) {
    print('❌ Error running Flutter preview: $e');
    print('💡 Make sure Flutter is properly installed and in your PATH.');
  }
}

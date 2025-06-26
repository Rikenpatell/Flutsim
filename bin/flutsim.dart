#!/usr/bin/env dart

import 'dart:io';
import 'package:args/args.dart';
import 'flutsim_run.dart';
import 'dart:convert';

const String version = '1.0.0';

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

/// Show Flutter installation instructions
void showFlutterInstallInstructions() {
  print('''
❌ Flutter is not installed or not found in PATH.

To install Flutter:

1. Download Flutter SDK from: https://docs.flutter.dev/get-started/install/windows
2. Extract it to a location like C:\\flutter
3. Add Flutter to your PATH:
   - Open System Properties > Advanced > Environment Variables
   - Add C:\\flutter\\bin to the PATH variable
4. Restart your terminal
5. Run: flutter doctor

Alternative: You can also run this command to add Flutter to PATH temporarily:
   set PATH=%PATH%;C:\\flutter\\bin
''');
}

/// Setup FlutSim-specific configuration for a new project
Future<void> _setupFlutsimProject(String projectName) async {
  try {
    print('🔧 Setting up FlutSim configuration...');

    // Create FlutSim configuration directory
    final configDir = Directory('$projectName/.flutsim');
    if (!await configDir.exists()) {
      await configDir.create(recursive: true);
    }

    // Create FlutSim configuration file
    final configFile = File('${configDir.path}/config.json');
    final config = {
      'projectName': projectName,
      'autoReload': true,
      'hotReload': true,
      'networkAccess': true,
      'qrCode': true,
      'createdAt': DateTime.now().toIso8601String(),
    };

    await configFile.writeAsString(jsonEncode(config));

    // Create FlutSim README
    final readmeFile = File('$projectName/FLUTSIM_README.md');
    final readmeContent = '''# FlutSim Configuration

This project has been configured with FlutSim for enhanced development experience.

## Features Enabled:
- ✅ Auto-reload on file changes
- ✅ Hot reload support
- ✅ Network access for mobile testing
- ✅ QR code generation for easy access

## Usage:
\`\`\`bash
# Run with FlutSim
flutsim run

# Or run normally
flutter run
\`\`\`

## Configuration:
Edit \`.flutsim/config.json\` to customize FlutSim behavior.
''';

    await readmeFile.writeAsString(readmeContent);

    print('✅ FlutSim configuration created successfully!');
    print('📖 Check FLUTSIM_README.md for usage instructions');
  } catch (e) {
    print('⚠️  Could not create FlutSim configuration: $e');
    print('💡 You can manually configure FlutSim later');
  }
}

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addCommand('create')
    ..addCommand('run')
    ..addFlag('version', abbr: 'v', help: 'Show version information')
    ..addFlag('help', abbr: 'h', help: 'Show this help message');

  try {
    final ArgResults argResults = parser.parse(arguments);

    // Handle version flag
    if (argResults['version'] == true) {
      print('FlutSim version $version');
      print('A powerful Flutter CLI tool for enhanced development experience');
      exit(0);
    }

    // Handle help flag
    if (argResults['help'] == true || arguments.isEmpty) {
      print('''
🚀 FlutSim - Enhanced Flutter Development Tool

Usage: flutsim <command> [arguments]

Commands:
  create <project_name>    Create a new Flutter project with FlutSim configuration
  run                     Run the current Flutter project with enhanced features
  --version, -v           Show version information
  --help, -h              Show this help message

Examples:
  flutsim create my_app
  flutsim create awesome_flutter_project
  flutsim run
  flutsim --version

Features:
  ✨ Auto-reload on file changes
  ⚡ Hot reload support
  🎨 Instant UI updates
  📱 QR code access for mobile testing
  🌐 Network access for cross-device testing
  🔧 Smart Flutter detection

For more information, visit: https://github.com/yourusername/flutsim
''');
      exit(0);
    }

    if (argResults.command?.name == 'create') {
      final rest = argResults.command?.rest;
      if (rest == null || rest.isEmpty) {
        print('❌ Please provide a project name.');
        print('Usage: flutsim create <project_name>');
        exit(1);
      }

      final projectName = rest.first;

      // Check if Flutter is installed
      if (!await isFlutterInstalled()) {
        print('❌ Flutter is not installed or not found in PATH.');

        // Try to find Flutter installation
        final flutterPath = getFlutterPath();
        if (flutterPath != null) {
          print('✅ Found Flutter at: $flutterPath');
          print('💡 You can add this to your PATH or use the full path.');
        } else {
          showFlutterInstallInstructions();
        }
        exit(1);
      }

      print('🚀 Creating Flutter project: $projectName');

      try {
        // Get the Flutter path to use full path instead of relying on PATH
        final flutterPath = getFlutterPath();
        final flutterCommand = flutterPath ?? 'flutter';

        final result = await Process.start(
          flutterCommand,
          ['create', projectName],
          mode: ProcessStartMode.inheritStdio,
        );

        final exitCode = await result.exitCode;

        if (exitCode == 0) {
          print('✅ Project "$projectName" created successfully!');
          print('📁 Navigate to your project: cd $projectName');

          // Add FlutSim-specific setup
          await _setupFlutsimProject(projectName);

          print('''
🎉 Your Flutter project is ready!

Next steps:
1. cd $projectName
2. flutsim run
3. Start developing! 🚀

For more information, check FLUTSIM_README.md
''');
        } else {
          print('❌ Failed to create Flutter project. Exit code: $exitCode');
        }
      } catch (e) {
        print('❌ Error creating Flutter project: $e');
        print('💡 Make sure Flutter is properly installed and in your PATH.');
      }
    } else if (argResults.command?.name == 'run') {
      await runFlutsim();
    } else {
      print('❌ Unknown command: ${argResults.command?.name}');
      print('Run "flutsim --help" for usage information.');
      exit(1);
    }
  } catch (e) {
    print('❌ Error: $e');
    print('Run "flutsim --help" for usage information.');
    exit(1);
  }
}

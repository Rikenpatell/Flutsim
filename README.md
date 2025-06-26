# FlutSim 🚀

A powerful Flutter CLI tool for enhanced development experience with auto-reload, hot reload, and instant UI updates.

## Features ✨

- 🚀 **Global CLI Tool** - Use `flutsim create` and `flutsim run` anywhere
- 🔄 **Auto-Reload** - Automatic page refresh on file changes
- ⚡ **Hot Reload** - Instant code updates without full rebuild
- 🎨 **Instant UI Updates** - Real-time UI changes
- 📱 **QR Code Access** - Easy mobile testing with QR codes
- 🌐 **Network Access** - Access your app from any device on the network
- 🔧 **Smart Flutter Detection** - Automatically finds Flutter installation
- ⚙️ **Configurable** - Customize behavior through configuration files

## Installation 📦

### Global Installation

```bash
# Install globally using pub
dart pub global activate flutsim

# Or install from git
dart pub global activate --source git https://github.com/yourusername/flutsim.git
```

### Prerequisites

- [Dart SDK](https://dart.dev/get-dart) (3.0.0 or higher)
- [Flutter SDK](https://flutter.dev/docs/get-started/install)

## Usage 🛠️

### Create a New Flutter Project

```bash
# Create a new Flutter project with FlutSim configuration
flutsim create my_awesome_app

# Navigate to your project
cd my_awesome_app
```

### Run Your Flutter Project

```bash
# Run with FlutSim enhanced features
flutsim run

# Or run normally with Flutter
flutter run
```

### Available Commands

```bash
flutsim create <project_name>    # Create a new Flutter project
flutsim run                      # Run current project with FlutSim
flutsim --help                   # Show help information
```

## Features in Detail 🔍

### Auto-Reload System

FlutSim automatically detects file changes and reloads your web application, providing instant feedback during development.

### Hot Reload Support

Experience lightning-fast development with hot reload capabilities that update your code without losing application state.

### Network Access

Access your Flutter web app from any device on your network using the provided IP address and QR code.

### Smart Configuration

FlutSim automatically creates configuration files for optimal development experience:

```json
{
  "projectName": "my_awesome_app",
  "autoReload": true,
  "hotReload": true,
  "networkAccess": true,
  "qrCode": true,
  "createdAt": "2024-01-01T00:00:00.000Z"
}
```

## Configuration ⚙️

### Project Configuration

Each FlutSim project includes a `.flutsim/config.json` file where you can customize:

- Auto-reload behavior
- Hot reload settings
- Network access permissions
- QR code generation
- Port configurations

### Global Configuration

Create a global configuration file at `~/.flutsim/config.json` for default settings across all projects.

## Development Workflow 💻

1. **Create Project**: `flutsim create my_app`
2. **Navigate**: `cd my_app`
3. **Run**: `flutsim run`
4. **Develop**: Make changes to your code
5. **See Changes**: Watch your app update automatically!

## Troubleshooting 🔧

### Flutter Not Found

If FlutSim can't find Flutter, it will:

1. Search common installation paths
2. Provide installation instructions
3. Suggest PATH configuration

### Port Conflicts

FlutSim automatically finds available ports if the default port is in use.

### Network Issues

- Ensure your firewall allows the application
- Check that you're on the same network as your devices
- Verify the IP address shown in the terminal

## Contributing 🤝

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

## License 📄

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support 💬

- 📧 Email: support@flutsim.dev
- 🐛 Issues: [GitHub Issues](https://github.com/yourusername/flutsim/issues)
- 📖 Documentation: [GitHub Wiki](https://github.com/yourusername/flutsim/wiki)

## Changelog 📝

See [CHANGELOG.md](CHANGELOG.md) for a list of changes and version history.

---

Made with ❤️ for the Flutter community

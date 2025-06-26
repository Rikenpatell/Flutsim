# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-01-01

### Added

- Initial release of FlutSim CLI tool
- `flutsim create <project_name>` command for creating new Flutter projects
- `flutsim run` command for running Flutter projects with enhanced features
- Auto-reload system for automatic page refresh on file changes
- Hot reload support for instant code updates
- Instant UI updates for real-time UI changes
- QR code generation for easy mobile testing
- Network access for cross-device testing
- Smart Flutter installation detection
- Configuration system with `.flutsim/config.json` files
- WebSocket-based live reload server
- Browser auto-reload functionality
- Flutter development proxy
- Instant UI server for real-time updates
- Cross-platform support (Windows, macOS, Linux)
- Comprehensive error handling and user feedback
- Automatic port detection and management
- IP address detection for network access

### Features

- Global CLI tool installation support
- Enhanced development workflow
- Intelligent Flutter path detection
- Project-specific configuration
- Real-time development feedback
- Network accessibility
- Mobile-friendly testing with QR codes

### Technical

- Built with Dart 3.0+ compatibility
- Uses shelf for web server functionality
- WebSocket implementation for live reload
- File watching capabilities
- Static file serving
- QR code generation
- Cross-platform path handling

# FlutSim - Flutter CLI Preview Tool

A simple CLI tool to create Flutter projects with ease.

## Prerequisites

Before using FlutSim, you need to have Flutter installed on your system.

### Installing Flutter

1. **Download Flutter SDK** from: https://docs.flutter.dev/get-started/install/windows
2. **Extract** the downloaded file to a location like `C:\flutter`
3. **Add Flutter to PATH**:
   - Open System Properties > Advanced > Environment Variables
   - Add `C:\flutter\bin` to the PATH variable
4. **Restart your terminal**
5. **Verify installation**: Run `flutter doctor`

## Quick Setup

If you're having trouble with Flutter PATH, use one of our setup scripts:

### Option 1: PowerShell (Recommended)

```powershell
.\bin\setup_flutter.ps1
```

### Option 2: Batch Script

```cmd
.\bin\setup_flutter.bat
```

These scripts will automatically find Flutter and add it to your PATH for the current session.

## Usage

### Create a new Flutter project

```bash
dart run bin/flutsim.dart create my_app
```

Or if you have FlutSim installed globally:

```bash
flutsim create my_app
```

### Examples

```bash
# Create a simple app
flutsim create todo_app

# Create a project with descriptive name
flutsim create awesome_flutter_project

# Create a project in current directory
flutsim create .
```

## What happens when you create a project?

1. FlutSim checks if Flutter is installed and accessible
2. Creates a new Flutter project with the specified name
3. Provides helpful next steps for development

## Troubleshooting

### "Flutter command not found" error

This means Flutter is not in your system PATH. Try these solutions:

1. **Use the setup scripts** (recommended):

   ```powershell
   .\bin\setup_flutter.ps1
   ```

2. **Add Flutter to PATH manually**:

   ```cmd
   set PATH=%PATH%;C:\flutter\bin
   ```

3. **Install Flutter** if not already installed:
   - Download from: https://docs.flutter.dev/get-started/install/windows
   - Extract to `C:\flutter`
   - Add `C:\flutter\bin` to PATH

### "Permission denied" error

Run PowerShell as Administrator and try again.

## Development

To contribute to FlutSim:

1. Clone the repository
2. Install dependencies: `dart pub get`
3. Run tests: `dart test`
4. Make your changes
5. Test your changes: `dart run bin/flutsim.dart create <project name>`

# Contributing to FlutSim

Thank you for your interest in contributing to FlutSim! This document provides guidelines and information for contributors.

## Getting Started

### Prerequisites

- [Dart SDK](https://dart.dev/get-dart) (3.0.0 or higher)
- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- Git

### Setting Up the Development Environment

1. Fork the repository
2. Clone your fork:

   ```bash
   git clone https://github.com/yourusername/flutsim.git
   cd flutsim
   ```

3. Install dependencies:

   ```bash
   dart pub get
   ```

4. Activate the package locally:
   ```bash
   dart pub global activate --source path .
   ```

## Development Workflow

### Making Changes

1. Create a new branch for your feature:

   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Make your changes
3. Test your changes thoroughly
4. Update documentation if necessary
5. Commit your changes with a descriptive message

### Testing

Run the tests to ensure everything works correctly:

```bash
dart test
```

### Code Style

- Follow Dart's official style guide
- Use meaningful variable and function names
- Add comments for complex logic
- Keep functions small and focused

## Submitting Changes

### Pull Request Process

1. Ensure your code follows the project's style guidelines
2. Update the README.md if you've added new features
3. Update the CHANGELOG.md with your changes
4. Submit a pull request with a clear description of your changes

### Commit Message Format

Use conventional commit format:

```
type(scope): description

[optional body]

[optional footer]
```

Examples:

- `feat(cli): add new command for project initialization`
- `fix(server): resolve port conflict issue`
- `docs(readme): update installation instructions`

## Issue Reporting

When reporting issues, please include:

- Operating system and version
- Dart/Flutter version
- Steps to reproduce the issue
- Expected vs actual behavior
- Any error messages or logs

## Feature Requests

When suggesting new features:

- Describe the problem you're trying to solve
- Explain how the feature would help
- Provide examples of how it would be used
- Consider the impact on existing functionality

## Code of Conduct

- Be respectful and inclusive
- Help others learn and grow
- Focus on the code and ideas, not the person
- Be open to feedback and constructive criticism

## License

By contributing to FlutSim, you agree that your contributions will be licensed under the same license as the project (MIT License).

## Questions?

If you have questions about contributing, feel free to:

- Open an issue for discussion
- Contact the maintainers
- Join our community discussions

Thank you for contributing to FlutSim! 🚀

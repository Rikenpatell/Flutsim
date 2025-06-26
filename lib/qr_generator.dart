import 'package:qr/qr.dart';

/// Utility class for QR code generation
class QRGenerator {
  /// Generates QR code data for a given URL
  static Future<String> generateQRCode(String url) async {
    try {
      // Validate URL
      if (url.isEmpty) {
        throw Exception('URL cannot be empty');
      }

      // Generate QR code data
      return _generateQRCodeString(url);
    } catch (e) {
      throw Exception('Failed to generate QR code: $e');
    }
  }

  /// Generates a simple string representation of QR code
  static String _generateQRCodeString(String data) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'qr_${timestamp}_${data.hashCode}';
  }

  /// Generates QR code as SVG string
  static Future<String> generateQRCodeSVG(String url,
      {int size = 100, int version = 2}) async {
    try {
      return _generateSVGString(url, size, version);
    } catch (e) {
      throw Exception('Failed to generate QR code SVG: $e');
    }
  }

  /// Generates a real QR code SVG string using the qr package
  static String _generateSVGString(String data, int size, int version) {
    final typeNumber = version.clamp(1, 10);
    final qrCode = QrCode(typeNumber, QrErrorCorrectLevel.L)..addData(data);
    final qrImage = QrImage(qrCode);
    final int moduleCount = qrImage.moduleCount;
    final double cellSize = size / moduleCount;
    final svg = StringBuffer();
    svg.write(
        '<svg width="$size" height="$size" viewBox="0 0 $size $size" xmlns="http://www.w3.org/2000/svg">');
    svg.write('<rect width="$size" height="$size" fill="white"/>');
    for (int y = 0; y < moduleCount; y++) {
      for (int x = 0; x < moduleCount; x++) {
        if (qrImage.isDark(y, x)) {
          final xPos = x * cellSize;
          final yPos = y * cellSize;
          svg.write(
              '<rect x="$xPos" y="$yPos" width="$cellSize" height="$cellSize" fill="black"/>');
        }
      }
    }
    svg.write('</svg>');
    return svg.toString();
  }

  /// Validates if a string can be encoded as QR code
  static bool isValidQRData(String data) {
    if (data.isEmpty) return false;

    // Check if data is not too long for QR code
    // QR codes have different capacity limits based on version and error correction
    return data.length <=
        2953; // Approximate limit for version 40 with M error correction
  }

  /// Gets the recommended QR code version for given data length
  static int getRecommendedVersion(int dataLength) {
    if (dataLength <= 25) return 1;
    if (dataLength <= 47) return 2;
    if (dataLength <= 77) return 3;
    if (dataLength <= 114) return 4;
    if (dataLength <= 154) return 5;
    if (dataLength <= 195) return 6;
    if (dataLength <= 224) return 7;
    if (dataLength <= 279) return 8;
    if (dataLength <= 335) return 9;
    if (dataLength <= 395) return 10;

    // For longer data, use auto version
    return 40; // Default to version 40 for auto
  }

  /// Generates QR code with custom styling
  static Future<String> generateStyledQRCode(
    String url, {
    int size = 20,
    int foregroundColor = 0xFF000000,
    int backgroundColor = 0xFFFFFFFF,
  }) async {
    try {
      // Generate actual QR code SVG with custom colors
      return _generateStyledSVGString(
          url, size, foregroundColor, backgroundColor);
    } catch (e) {
      throw Exception('Failed to generate styled QR code: $e');
    }
  }

  /// Generates styled SVG QR code
  static String _generateStyledSVGString(
      String data, int size, int foregroundColor, int backgroundColor) {
    final typeNumber = getRecommendedVersion(data.length);
    final qrCode = QrCode(typeNumber, QrErrorCorrectLevel.L)..addData(data);
    final qrImage = QrImage(qrCode);
    final int moduleCount = qrImage.moduleCount;
    final double cellSize = size / moduleCount;

    final fgColor = '#${foregroundColor.toRadixString(16).padLeft(6, '0')}';
    final bgColor = '#${backgroundColor.toRadixString(16).padLeft(6, '0')}';

    final svg = StringBuffer();
    svg.write(
        '<svg width="$size" height="$size" viewBox="0 0 $size $size" xmlns="http://www.w3.org/2000/svg">');
    svg.write('<rect width="$size" height="$size" fill="$bgColor"/>');
    for (int y = 0; y < moduleCount; y++) {
      for (int x = 0; x < moduleCount; x++) {
        if (qrImage.isDark(y, x)) {
          final xPos = x * cellSize;
          final yPos = y * cellSize;
          svg.write(
              '<rect x="$xPos" y="$yPos" width="$cellSize" height="$cellSize" fill="$fgColor"/>');
        }
      }
    }
    svg.write('</svg>');
    return svg.toString();
  }

  /// Prints a QR code for the given data to the terminal as ASCII
  /// [size] controls the QR version (1-10, default 4, smaller = smaller QR)
  static void printQRCodeToTerminal(String data, {int size = 4}) {
    try {
      final typeNumber = size.clamp(1, 10);
      final qrCode = QrCode(typeNumber, QrErrorCorrectLevel.L)..addData(data);
      final qrImage = QrImage(qrCode);
      final int moduleCount = qrImage.moduleCount;

      print('\n📱 QR Code for: $data');
      print('┌${'─' * (moduleCount * 2)}┐');

      for (int y = 0; y < moduleCount; y++) {
        final buffer = StringBuffer('│');
        for (int x = 0; x < moduleCount; x++) {
          buffer.write(qrImage.isDark(y, x) ? '██' : '  ');
        }
        buffer.write('│');
        print(buffer.toString());
      }

      print('└${'─' * (moduleCount * 2)}┘');
      print('📱 Scan this QR code with your mobile device');
    } catch (e) {
      print('❌ Failed to generate QR code for terminal: $e');
    }
  }

  /// Generates a simple ASCII QR code for terminal display
  static String generateSimpleQRCode(String data) {
    try {
      final typeNumber = 2; // Small QR code
      final qrCode = QrCode(typeNumber, QrErrorCorrectLevel.L)..addData(data);
      final qrImage = QrImage(qrCode);
      final int moduleCount = qrImage.moduleCount;

      final buffer = StringBuffer();
      buffer.writeln('┌${'─' * (moduleCount * 2)}┐');

      for (int y = 0; y < moduleCount; y++) {
        buffer.write('│');
        for (int x = 0; x < moduleCount; x++) {
          buffer.write(qrImage.isDark(y, x) ? '██' : '  ');
        }
        buffer.writeln('│');
      }

      buffer.write('└${'─' * (moduleCount * 2)}┘');
      return buffer.toString();
    } catch (e) {
      return '❌ Failed to generate QR code: $e';
    }
  }
}

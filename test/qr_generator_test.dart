import 'package:test/test.dart';
import 'package:flutsim/qr_generator.dart';

void main() {
  group('QRGenerator', () {
    test('generateQRCode returns a string', () async {
      final qr = await QRGenerator.generateQRCode('https://example.com');
      expect(qr, isA<String>());
      expect(qr, contains('qr_'));
    });

    test('generateQRCodeSVG returns SVG string', () async {
      final svg = await QRGenerator.generateQRCodeSVG('https://example.com');
      expect(svg, startsWith('<svg'));
      expect(svg, contains('rect'));
    });

    test('isValidQRData returns true for short data', () {
      expect(QRGenerator.isValidQRData('hello'), isTrue);
    });

    test('isValidQRData returns false for empty data', () {
      expect(QRGenerator.isValidQRData(''), isFalse);
    });

    test('getRecommendedVersion returns correct version', () {
      expect(QRGenerator.getRecommendedVersion(10), equals(1));
      expect(QRGenerator.getRecommendedVersion(50), equals(3));
      expect(QRGenerator.getRecommendedVersion(400), equals(40));
      expect(QRGenerator.getRecommendedVersion(3000), equals(40));
    });

    test('generateSimpleQRCode returns ASCII art', () {
      final ascii = QRGenerator.generateSimpleQRCode('test');
      expect(ascii, contains('┌'));
      expect(ascii, contains('┘'));
    });
  });
}

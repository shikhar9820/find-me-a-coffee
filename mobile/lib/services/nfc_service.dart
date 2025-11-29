import 'dart:async';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:vibration/vibration.dart';

class NfcResult {
  final bool success;
  final String? cafeId;
  final String? error;

  NfcResult.success(this.cafeId)
      : success = true,
        error = null;

  NfcResult.failure(this.error)
      : success = false,
        cafeId = null;
}

class NfcService {
  static final NfcService _instance = NfcService._internal();
  factory NfcService() => _instance;
  NfcService._internal();

  bool _isScanning = false;
  final StreamController<NfcResult> _resultController =
      StreamController<NfcResult>.broadcast();

  Stream<NfcResult> get resultStream => _resultController.stream;
  bool get isScanning => _isScanning;

  /// Check if NFC is available on this device
  Future<bool> isAvailable() async {
    return await NfcManager.instance.isAvailable();
  }

  /// Start listening for NFC tags
  Future<void> startSession({
    required Function(String cafeId) onCafeTagDetected,
    Function(String error)? onError,
  }) async {
    if (_isScanning) return;

    final isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) {
      onError?.call('NFC is not available on this device');
      return;
    }

    _isScanning = true;

    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        try {
          final cafeId = await _extractCafeId(tag);

          if (cafeId != null) {
            // Haptic feedback for successful scan
            if (await Vibration.hasVibrator() ?? false) {
              Vibration.vibrate(duration: 100);
            }

            onCafeTagDetected(cafeId);
            _resultController.add(NfcResult.success(cafeId));
          } else {
            final error = 'Invalid tag - not a FindMeACoffee tag';
            onError?.call(error);
            _resultController.add(NfcResult.failure(error));
          }
        } catch (e) {
          final error = 'Error reading tag: $e';
          onError?.call(error);
          _resultController.add(NfcResult.failure(error));
        }
      },
      onError: (error) async {
        _isScanning = false;
        final errorMsg = 'NFC Error: ${error.message}';
        onError?.call(errorMsg);
        _resultController.add(NfcResult.failure(errorMsg));
      },
    );
  }

  /// Stop the NFC session
  Future<void> stopSession() async {
    if (!_isScanning) return;
    _isScanning = false;
    await NfcManager.instance.stopSession();
  }

  /// Extract cafe ID from NFC tag
  /// Expected URL format: findmeacoffee://stamp/{cafe_uuid}
  /// Or: https://findmeacoffee.in/stamp/{cafe_uuid}
  Future<String?> _extractCafeId(NfcTag tag) async {
    final ndef = Ndef.from(tag);
    if (ndef == null) return null;

    final cachedMessage = ndef.cachedMessage;
    if (cachedMessage == null) return null;

    for (final record in cachedMessage.records) {
      // Check if it's a URI record
      if (record.typeNameFormat == NdefTypeNameFormat.nfcWellknown) {
        final payload = record.payload;
        if (payload.isEmpty) continue;

        String uri;
        // URI record type
        if (record.type.length == 1 && record.type[0] == 0x55) {
          // First byte is URI identifier code
          final uriPrefix = _getUriPrefix(payload[0]);
          uri = uriPrefix + String.fromCharCodes(payload.sublist(1));
        } else {
          // Text record or other
          uri = String.fromCharCodes(payload);
        }

        // Parse the cafe ID from URL
        final cafeId = _parseCafeIdFromUri(uri);
        if (cafeId != null) return cafeId;
      }
    }

    return null;
  }

  /// Get URI prefix based on NFC URI identifier code
  String _getUriPrefix(int code) {
    const prefixes = {
      0x00: '',
      0x01: 'http://www.',
      0x02: 'https://www.',
      0x03: 'http://',
      0x04: 'https://',
      // Add more as needed
    };
    return prefixes[code] ?? '';
  }

  /// Parse cafe ID from URI
  /// Supports:
  /// - findmeacoffee://stamp/{uuid}
  /// - https://findmeacoffee.in/stamp/{uuid}
  /// - https://fmac.in/s/{uuid}
  String? _parseCafeIdFromUri(String uri) {
    // Custom scheme
    final customSchemeRegex = RegExp(r'findmeacoffee://stamp/([a-f0-9-]+)');
    var match = customSchemeRegex.firstMatch(uri.toLowerCase());
    if (match != null) return match.group(1);

    // Web URL
    final webUrlRegex =
        RegExp(r'https?://(?:findmeacoffee\.in|fmac\.in)/(?:stamp|s)/([a-f0-9-]+)');
    match = webUrlRegex.firstMatch(uri.toLowerCase());
    if (match != null) return match.group(1);

    return null;
  }

  void dispose() {
    _resultController.close();
  }
}

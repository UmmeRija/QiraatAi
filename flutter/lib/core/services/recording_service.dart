// recording_service.dart
// FIXED: Do NOT pass path: '' on web - even empty string triggers dart:io _Namespace crash
// On web, omit the path parameter entirely. record package returns a blob URL from stop().
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

class RecordingService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _lastPath;

  Future<void> startRecording() async {
    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        throw Exception('Microphone permission not granted');
      }

      final config = RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        bitRate: 128000,
        numChannels: 1,
      );

      if (kIsWeb) {
        // Use a placeholder filename for web.
        // Even though web doesn't have a filesystem, providing a filename hint
        // is better than an empty string which might trigger internal dart:io checks.
        await _audioRecorder.start(config, path: 'recitation.wav');
        _lastPath = null;
        debugPrint('[RecordingService] Web recording started');
      } else {
        // Mobile/Desktop: simple DateTime-based path (no path_provider needed)
        final path =
            '/tmp/recitation_${DateTime.now().millisecondsSinceEpoch}.wav';
        await _audioRecorder.start(config, path: path);
        _lastPath = path;
        debugPrint('[RecordingService] Mobile recording started: $path');
      }
    } catch (e) {
      debugPrint('[RecordingService] Start error: $e');
      throw Exception('Failed to start recording: $e');
    }
  }

  // On web: returns blob URL (e.g. blob:http://...)
  // On mobile: returns file path
  Future<String?> stopRecording() async {
    try {
      final result = await _audioRecorder.stop();
      debugPrint('[RecordingService] Stopped. Result: $result');
      return result;
    } catch (e) {
      debugPrint('[RecordingService] Stop error: $e');
      throw Exception('Failed to stop recording: $e');
    }
  }

  Future<bool> isRecording() async {
    return await _audioRecorder.isRecording();
  }

  String? get lastPath => _lastPath;

  void dispose() {
    _audioRecorder.dispose();
  }
}

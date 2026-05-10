import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

class ApiService {
  final Dio _dio;

  ApiService(this._dio);

  /// Public getter for direct API access by other features
  Dio get dio => _dio;

  // 1. Fetch all Surahs
  Future<List<Map<String, dynamic>>> getSurahs() async {
    try {
      final response = await _dio.get('/api/v1/surahs');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      throw Exception('Failed to load Surahs: $e');
    }
  }

  // 2. Fetch Words for a Surah
  Future<Map<String, dynamic>> getSurahWords(int surahId) async {
    try {
      final response = await _dio.get('/api/v1/surah/$surahId');
      return response.data;
    } catch (e) {
      throw Exception('Failed to load Surah words: $e');
    }
  }

  // 3. Analyze Recitation
  Future<Map<String, dynamic>> analyzeRecitation({
    required int surahId,
    int? startAyah,
    int? endAyah,
    required String audioPath,
    bool saveSession = true,
  }) async {
    try {
      MultipartFile file;
      if (kIsWeb) {
        final response = await Dio().get<List<int>>(
          audioPath,
          options: Options(responseType: ResponseType.bytes),
        );
        
        if (response.data == null) {
          throw Exception('Failed to read audio data from blob');
        }

        file = MultipartFile.fromBytes(
          response.data!,
          filename: 'recitation.wav',
        );
      } else {
        file = await MultipartFile.fromFile(
          audioPath,
          filename: 'recitation.wav',
        );
      }

      final Map<String, dynamic> fields = {
        'surah_id': surahId,
        'save_session': saveSession,
        'file': file,
      };

      if (startAyah != null) fields['start_ayah'] = startAyah;
      if (endAyah != null) fields['end_ayah'] = endAyah;

      final formData = FormData.fromMap(fields);

      final response = await _dio.post(
        '/api/v1/analyze-recitation',
        data: formData,
      );
      return response.data;
    } on DioException catch (e) {
      String errorMessage = "Unknown error";
      if (e.response != null) {
        errorMessage = e.response?.data['detail'] ?? "Server error";
      } else {
        errorMessage = "Connection error: ${e.message}";
      }
      throw Exception('Analysis failed: $errorMessage');
    } catch (e) {
      throw Exception('Analysis failed: $e');
    }
  }

  // 4. Get User Stats
  Future<Map<String, dynamic>> getStats() async {
    try {
      final response = await _dio.get('/api/v1/stats');
      return response.data;
    } catch (e) {
      throw Exception('Failed to load stats: $e');
    }
  }

// 5. Get Recent Sessions
   Future<List<Map<String, dynamic>>> getSessions({int limit = 10}) async {
     try {
       final response = await _dio.get('/api/v1/sessions', queryParameters: {'limit': limit});
       return List<Map<String, dynamic>>.from(response.data);
     } catch (e) {
       throw Exception('Failed to load sessions: $e');
     }
   }

   // 6. Get Kanzul Iman Translation for a Surah
   Future<Map<String, dynamic>> getKanzulImanSurah(int surahId) async {
     try {
       final response = await _dio.get('/quran/surah/$surahId/kanzuliman');
       return response.data;
     } catch (e) {
       throw Exception('Failed to load Kanzul Iman translation: $e');
     }
   }

   // 7. Get Surah Info (Shaane Nuzool)
   Future<Map<String, dynamic>> getSurahInfo(int surahId) async {
     try {
       final response = await _dio.get('/quran/surah/$surahId/info');
       return response.data;
     } catch (e) {
       throw Exception('Failed to load Surah info: $e');
     }
   }
}

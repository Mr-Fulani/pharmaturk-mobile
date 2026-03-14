import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/public_user_profile.dart';

class UserService {
  final ApiClient _apiClient = ApiClient();

  /// Получить публичный профиль пользователя.
  /// [username] — username пользователя (опционально при testimonialId).
  /// [testimonialId] — ID отзыва для поиска пользователя (опционально).
  Future<PublicUserProfile> getPublicProfile({
    String? username,
    int? testimonialId,
  }) async {
    if (username == null && testimonialId == null) {
      throw ArgumentError('Требуется username или testimonialId');
    }
    try {
      final queryParams = <String, dynamic>{};
      if (username != null) queryParams['username'] = username;
      if (testimonialId != null) queryParams['testimonial_id'] = testimonialId;

      final response = await _apiClient.dio.get(
        '/users/public-profile/',
        queryParameters: queryParams,
      );
      return PublicUserProfile.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Проверяет, является ли ошибка «профиль не публичный» (403).
  static bool isProfileNotPublicError(String error) {
    return error.contains('Профиль не является публичным') ||
        error.contains('Profile is not public');
  }

  /// Проверяет, является ли ошибка «пользователь не найден» (404).
  static bool isUserNotFoundError(String error) {
    return error.contains('Пользователь не найден') ||
        error.contains('User not found');
  }

  String _handleError(dynamic error) {
    if (error is DioException) {
      if (error.response != null) {
        final data = error.response!.data;
        if (data is Map<String, dynamic>) {
          if (data.containsKey('error')) {
            return data['error'].toString();
          }
          if (data.containsKey('detail')) {
            return data['detail'].toString();
          }
        }
        return 'Ошибка сервера: ${error.response!.statusCode}';
      }
      return 'Ошибка соединения: ${error.message}';
    }
    return 'Неизвестная ошибка: $error';
  }
}

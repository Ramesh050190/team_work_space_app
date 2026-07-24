import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:team_workspace/core/constants/api_constants.dart';
import 'package:team_workspace/core/exceptions/network_exception.dart';
import 'package:team_workspace/core/exceptions/server_exception.dart';
import 'package:team_workspace/core/logger/app_logger.dart';
import 'package:team_workspace/core/network/mock_task_interceptor.dart';

class ApiClient {
  ApiClient({
    required String baseUrl,
    required AppLogger logger,
    Dio? dio,
    required bool enableTaskMock,
  }) : _dio = dio ?? Dio() {
    _dio
      ..options = BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        sendTimeout: ApiConstants.sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      )
      ..interceptors.addAll([
        if (enableTaskMock) MockTaskInterceptor(),
        if (kDebugMode)
          PrettyDioLogger(
            requestHeader: true,
            requestBody: true,
            responseBody: true,
            responseHeader: false,
            compact: true,
          ),
        InterceptorsWrapper(
          onError: (error, handler) {
            logger.error('API Error', error, error.stackTrace);
            handler.next(_mapDioError(error));
          },
        ),
      ]);
  }

  final Dio _dio;

  Dio get dio => _dio;

  DioException _mapDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return DioException(
          requestOptions: error.requestOptions,
          error: const NetworkException(
            message: 'No internet connection or request timed out.',
          ),
        );
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message =
            error.response?.data?.toString() ?? 'Server error occurred.';
        return DioException(
          requestOptions: error.requestOptions,
          response: error.response,
          error: ServerException(message: message, statusCode: statusCode),
        );
      default:
        return DioException(
          requestOptions: error.requestOptions,
          error: ServerException(
            message: error.message ?? 'Unknown network error.',
          ),
        );
    }
  }
}

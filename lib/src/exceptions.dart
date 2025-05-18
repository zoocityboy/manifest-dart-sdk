import 'dart:convert';
import 'package:http/http.dart' as http;

/// Base class for all Manifest SDK exceptions
class ManifestException implements Exception {
  /// The error message
  final String message;

  /// Optional stack trace
  final dynamic stackTrace;

  /// Constructor
  const ManifestException(this.message, [this.stackTrace]);

  @override
  String toString() => 'ManifestException: $message';
}

/// Exception thrown when there's a network connectivity issue
class NetworkException extends ManifestException {
  /// The original exception
  final dynamic originalException;

  /// Constructor
  NetworkException(String message, this.originalException, [dynamic stackTrace]) : super(message, stackTrace);

  @override
  String toString() => 'NetworkException: $message\nOriginal exception: $originalException';
}

/// Exception thrown for API errors
class ApiException extends ManifestException {
  /// HTTP status code
  final int statusCode;

  /// Raw response body
  final String body;

  /// Response headers
  final Map<String, String>? headers;

  /// Parsed error data if available
  final Map<String, dynamic>? errorData;

  /// Constructor
  ApiException(String message, this.statusCode, this.body, {this.headers, this.errorData, dynamic stackTrace})
    : super(message, stackTrace);

  @override
  String toString() => 'ApiException: $message (Status Code: $statusCode)';

  /// Factory constructor to create from HTTP response
  factory ApiException.fromResponse(http.Response response) {
    Map<String, dynamic>? errorData;
    String message = 'API Error: ${response.statusCode}';

    try {
      errorData = json.decode(response.body) as Map<String, dynamic>;
      // Try to extract a message from the error data
      if (errorData.containsKey('message')) {
        message = errorData['message'] as String;
      } else if (errorData.containsKey('error')) {
        if (errorData['error'] is String) {
          message = errorData['error'] as String;
        } else if (errorData['error'] is Map && errorData['error']['message'] != null) {
          message = errorData['error']['message'] as String;
        }
      }
    } catch (e) {
      // Could not parse the response body as JSON
    }

    return ApiException(message, response.statusCode, response.body, headers: response.headers, errorData: errorData);
  }
}

/// Exception thrown for authentication errors (401, 403)
class AuthenticationException extends ApiException {
  /// Constructor
  AuthenticationException(
    super.message,
    super.statusCode,
    super.body, {
    super.headers,
    super.errorData,
    super.stackTrace,
  });

  @override
  String toString() => 'AuthenticationException: $message (Status Code: $statusCode)';

  /// Factory constructor to create from HTTP response
  factory AuthenticationException.fromResponse(http.Response response) {
    final apiException = ApiException.fromResponse(response);
    return AuthenticationException(
      apiException.message,
      response.statusCode,
      response.body,
      headers: response.headers,
      errorData: apiException.errorData,
    );
  }
}

/// Exception thrown for validation errors (typically 422)
class ValidationException extends ApiException {
  /// Validation errors by field
  final Map<String, List<String>>? validationErrors;

  /// Constructor
  ValidationException(
    super.message,
    super.statusCode,
    super.body, {
    super.headers,
    super.errorData,
    this.validationErrors,
    super.stackTrace,
  });

  @override
  String toString() {
    if (validationErrors != null && validationErrors!.isNotEmpty) {
      return 'ValidationException: $message\nValidation errors: $validationErrors';
    }
    return 'ValidationException: $message';
  }

  /// Factory constructor to create from HTTP response
  factory ValidationException.fromResponse(http.Response response) {
    final apiException = ApiException.fromResponse(response);
    Map<String, List<String>>? validationErrors;

    try {
      final errorData = json.decode(response.body) as Map<String, dynamic>;
      if (errorData.containsKey('errors') && errorData['errors'] is Map) {
        validationErrors = {};
        final errorsMap = errorData['errors'] as Map<String, dynamic>;
        errorsMap.forEach((field, errors) {
          if (errors is List) {
            validationErrors![field] = (errors).map((e) => e.toString()).toList();
          } else if (errors is String) {
            validationErrors![field] = [errors];
          }
        });
      }
    } catch (e) {
      // Could not parse validation errors
    }

    return ValidationException(
      apiException.message,
      response.statusCode,
      response.body,
      headers: response.headers,
      errorData: apiException.errorData,
      validationErrors: validationErrors,
    );
  }
}

/// Exception thrown for not found errors (404)
class NotFoundException extends ApiException {
  /// Constructor
  NotFoundException(
    String message,
    String body, {
    Map<String, String>? headers,
    Map<String, dynamic>? errorData,
    dynamic stackTrace,
  }) : super(message, 404, body, headers: headers, errorData: errorData, stackTrace: stackTrace);

  @override
  String toString() => 'NotFoundException: $message';

  /// Factory constructor to create from HTTP response
  factory NotFoundException.fromResponse(http.Response response) {
    final apiException = ApiException.fromResponse(response);
    return NotFoundException(
      apiException.message,
      response.body,
      headers: response.headers,
      errorData: apiException.errorData,
    );
  }
}

/// Exception thrown for server errors (5xx)
class ServerException extends ApiException {
  /// Constructor
  ServerException(super.message, super.statusCode, super.body, {super.headers, super.errorData, super.stackTrace});

  @override
  String toString() => 'ServerException: $message (Status Code: $statusCode)';

  /// Factory constructor to create from HTTP response
  factory ServerException.fromResponse(http.Response response) {
    final apiException = ApiException.fromResponse(response);
    return ServerException(
      apiException.message,
      response.statusCode,
      response.body,
      headers: response.headers,
      errorData: apiException.errorData,
    );
  }
}

/// Exception thrown for rate limiting (429)
class RateLimitException extends ApiException {
  /// When the rate limit will reset
  final DateTime? resetTime;

  /// Maximum requests allowed
  final int? limit;

  /// Remaining requests
  final int? remaining;

  /// Constructor
  RateLimitException(
    String message,
    String body, {
    Map<String, String>? headers,
    Map<String, dynamic>? errorData,
    this.resetTime,
    this.limit,
    this.remaining,
    dynamic stackTrace,
  }) : super(message, 429, body, headers: headers, errorData: errorData, stackTrace: stackTrace);

  @override
  String toString() {
    if (limit != null && remaining != null) {
      return 'RateLimitException: $message (Limit: $limit, Remaining: $remaining, Reset: $resetTime)';
    }
    return 'RateLimitException: $message';
  }

  /// Factory constructor to create from HTTP response
  factory RateLimitException.fromResponse(http.Response response) {
    final apiException = ApiException.fromResponse(response);

    DateTime? resetTime;
    int? limit;
    int? remaining;

    if (response.headers.containsKey('x-ratelimit-reset')) {
      try {
        final resetTimestamp = int.parse(response.headers['x-ratelimit-reset']!);
        resetTime = DateTime.fromMillisecondsSinceEpoch(resetTimestamp * 1000);
      } catch (_) {}
    }

    if (response.headers.containsKey('x-ratelimit-limit')) {
      try {
        limit = int.parse(response.headers['x-ratelimit-limit']!);
      } catch (_) {}
    }

    if (response.headers.containsKey('x-ratelimit-remaining')) {
      try {
        remaining = int.parse(response.headers['x-ratelimit-remaining']!);
      } catch (_) {}
    }

    return RateLimitException(
      apiException.message,
      response.body,
      headers: response.headers,
      errorData: apiException.errorData,
      resetTime: resetTime,
      limit: limit,
      remaining: remaining,
    );
  }
}

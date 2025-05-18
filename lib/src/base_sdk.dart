/// Base SDK class for Manifest
abstract class BaseSDK {
  /// Base path for the API
  String slug = '';

  /// determine if the current instance is a single entity
  bool isSingleEntity = false;

  /// Request query parameters
  Map<String, dynamic> queryParams = {};
}

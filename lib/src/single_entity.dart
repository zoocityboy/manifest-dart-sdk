part of 'manifest_dart_sdk.dart';

/// Class for handling single entity operations
class SingleEntity {
  final Manifest _manifest;

  SingleEntity(this._manifest);

  /// Fetches a single entity by slug.
  ///
  /// Returns a Future resolving to the single entity.
  Future<T> get<T>() async {
    final response = await _manifest._fetch(path: '/singles/${_manifest.slug}');

    return response as T;
  }

  /// Updates a single entity by slug doing a full replacement (PUT).
  ///
  /// [data] The data to update the single entity with.
  /// Returns a Future resolving to the updated single entity.
  Future<T> update<T>(Map<String, dynamic> data) async {
    final response = await _manifest._fetch(path: '/singles/${_manifest.slug}', method: 'PUT', body: data);

    return response as T;
  }

  /// Updates a single entity by slug doing a partial replacement (PATCH).
  ///
  /// [data] The data to update the single entity with.
  /// Returns a Future resolving to the updated single entity.
  Future<T> patch<T>(Map<String, dynamic> data) async {
    final response = await _manifest._fetch(path: '/singles/${_manifest.slug}', method: 'PATCH', body: data);

    return response as T;
  }
}

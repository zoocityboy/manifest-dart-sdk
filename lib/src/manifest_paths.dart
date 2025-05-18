/// API endpoint paths
class ManifestPaths {
  static const String singles = 'singles/:slug';
  static const String collections = 'collections/:slug';
  static const String collectionsWithId = 'collections/:slug/:id';
  static const String login = 'auth/:slug/login';
  static const String signup = 'auth/:slug/signup';
  static const String me = 'auth/:slug/me';
  static const String uploadFile = 'upload/file';
  static const String uploadImage = 'upload/image';
}

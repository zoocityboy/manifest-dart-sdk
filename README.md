<p align="center">
  <a href="https://manifest.build/#gh-light-mode-only">
    <picture id="github_header">
      <source media="(prefers-color-scheme: dark)" srcset="https://manifest.build/assets/images/logo-transparent.svg">
      <img alt="Doki Dont kill my app!" src="https://manifest.build/assets/images/logo-transparent.svg" height="55px" alt="Manifest logo" title="Manifest - The 1-file micro-backend">
    </picture>
  </a>
</p>

Developed by 🦏 [zoocityboy][zoocityboy_link]


# Manifest Dart SDK

![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat-square&logo=flutter&logoColor=white)
[![Pub](https://img.shields.io/pub/v/manifest-dart-sdk.svg?style=flat-square)](https://pub.dev/packages/manifest-dart-sdk)
[![pub points](https://img.shields.io/pub/points/manifest-dart-sdk?style=flat-square&color=2E8B57&label=pub%20points)](https://pub.dev/packages/manifest-dart-sdk/score)
[![ci](https://github.com/zoocityboy/manifest-dart-sdk/actions/workflows/ci.yaml/badge.svg?style=flat-square)](https://github.com/zoocityboy/manifest-dart-sdk/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg?style=flat-square)](https://opensource.org/licenses/MIT)


A Dart client SDK for interacting with Manifest backend services. This SDK provides a clean and intuitive interface for communication with your Manifest backend, handling authentication, CRUD operations, and file uploads.

## Features

- 🔐 **Authentication** - Login, signup, and logout functionality
- 📝 **Singles Management** - Get and update single entities
- 📋 **Collections Management** - Full CRUD operations on collection entities  
- 📎 **File Uploads** - Upload files and images
- 🖼️ **Image Processing** - Handle image uploads with multiple sizes
- 📄 **Pagination Support** - Paginate through large collections

## Installation

Add this package to your project's dependencies:

```yaml
dependencies:
  manifest-dart-sdk: ^0.1.1
```

Then run:

```bash
dart pub get
```

## Usage

### Initialize the client

```dart
import 'package:manifest-dart-sdk/manifest-dart-sdk.dart';

void main() {
  // Default URL is http://localhost:1111
  final client = Manifest();
  
  // Or specify a custom URL
  final customClient = Manifest('https://your-manifest-backend.com');
}
```

### Working with Singles

Singles are standalone entities that don't belong to a collection.

```dart
// Get a single entity
var about = await client.single('about').get<Map<String, dynamic>>();
print('About page: ${about['title']}');

// Update a single entity (full replacement)
var updated = await client.single('about').update<Map<String, dynamic>>({
  'title': 'Updated About Page',
  'content': 'This is the updated about page content.'
});

// Partially update a single entity
var patched = await client.single('about').patch<Map<String, dynamic>>({
  'title': 'Patched About Page'
});
```

### Working with Collections

Collections are groups of similar entities.

```dart
// Get a paginated list of items
var posts = await client.from('posts').find(page: 1, perPage: 10);
posts.data.forEach((post) {
  print('- ${post['title']}');
});

// Get a single item by ID
var post = await client.from('posts').findOneById(1);

// Create a new item
var newPost = await client.from('posts').create({
  'title': 'New Post',
  'content': 'This is a new post'
});

// Update an item (full replacement)
var updatedPost = await client.from('posts').update(1, {
  'title': 'Updated Post',
  'content': 'This post was updated'
});

// Partially update an item
var patchedPost = await client.from('posts').patch(1, {
  'title': 'Patched Post'
});

// Delete an item
int deletedId = await client.from('posts').delete(1);
```

### Authentication

```dart
// Login
bool loggedIn = await client.login('users', 'user@example.com', 'password123');

// Get current user
var currentUser = await client.from('users').me();

// Logout
client.logout();

// Signup
bool signedUp = await client.signup('users', 'newuser@example.com', 'password123');
```

### File Uploads

```dart
import 'dart:io';
import 'dart:typed_data';

// Upload a file
File file = File('document.pdf');
Uint8List fileBytes = await file.readAsBytes();
var uploadResult = await client.from('documents')
    .upload('attachment', fileBytes, 'document.pdf');
print('Uploaded file path: ${uploadResult['path']}');

// Upload an image
File imageFile = File('image.jpg');
Uint8List imageBytes = await imageFile.readAsBytes();
var imageResult = await client.from('posts')
    .uploadImage('featured_image', imageBytes, 'image.jpg');
print('Uploaded image paths: $imageResult');

// Get image URL by size
String imageUrl = client.imageUrl(imageResult, 'medium');
```

## Error Handling

The SDK provides a robust exception hierarchy for proper error handling:

```dart
try {
  await client.from('posts').findOneById(999);
} on NotFoundException catch (e) {
  print('Post not found: ${e.message}');
} on AuthenticationException catch (e) {
  print('Authentication error: ${e.message}');
} on ValidationException catch (e) {
  print('Validation error:');
  if (e.validationErrors != null) {
    e.validationErrors!.forEach((field, errors) {
      print('  - $field: ${errors.join(', ')}');
    });
  }
} on ApiException catch (e) {
  print('API error (${e.statusCode}): ${e.message}');
} on NetworkException catch (e) {
  print('Network error: ${e.message}');
  print('Original exception: ${e.originalException}');
} on ManifestException catch (e) {
  print('General SDK error: ${e.message}');
} catch (e) {
  print('Unexpected error: $e');
}
```

### Exception Types

The SDK throws the following exception types:

| Exception Type | Description | Status Codes |
|----------------|-------------|--------------|
| `NetworkException` | Network connectivity issues | N/A |
| `AuthenticationException` | Authentication issues | 401, 403 |
| `ValidationException` | Validation errors | 422 |
| `NotFoundException` | Resource not found | 404 |
| `ServerException` | Server-side errors | 500-599 |
| `RateLimitException` | Rate limit exceeded | 429 |
| `ApiException` | Generic API errors | Any error status code |
| `ManifestException` | Base exception class | N/A |

### Accessing Error Details

Most exception types provide additional error details:

```dart
try {
  // Operation that might fail
} on ApiException catch (e) {
  print('Status code: ${e.statusCode}');
  print('Error message: ${e.message}');
  print('Response body: ${e.body}');
  print('Error data: ${e.errorData}');
}
```

Validation errors provide field-specific error messages:

```dart
try {
  await client.from('posts').create({'incomplete': 'data'});
} on ValidationException catch (e) {
  e.validationErrors?.forEach((field, errors) {
    print('$field: ${errors.join(', ')}');
  });
}
```

## Type Safety

You can use generics to get better type safety:

```dart
// Define a class for your entities
class Post {
  final int id;
  final String title;
  final String content;
  
  Post({required this.id, required this.title, required this.content});
  
  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      title: json['title'],
      content: json['content'],
    );
  }
}

// Use the fromJson parameter with find to get typed objects
var posts = await client.from('posts').find<Post>(
  fromJson: (json) => Post.fromJson(json)
);

// Now posts.data contains a List<Post>
for (var post in posts.data) {
  print('Post ${post.id}: ${post.title}');
}
```

## WASM Compatibility

This package is compatible with Dart's WebAssembly (WASM) target. All HTTP operations use the `http` package, which supports WASM and web environments. No `dart:io` dependencies are present.

## Complete Example

See the `/example` folder for a complete example of using the SDK.

## License

MIT
--------

<picture id="github_zoocityboy">
  <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/zoocityboy/zoo_brand/main/styles/README/zoocityboy_light.png">
  <img alt="Flutter developer Zoocityboy" src="https://raw.githubusercontent.com/zoocityboy/zoo_brand/main/styles/README/zoocityboy_dark.png">
</picture>

[logo_black]:https://raw.githubusercontent.com/zoocityboy/zoo_brand/main/styles/README/zoocityboy_dark.png#gh-light-mode-only
[logo_white]: https://raw.githubusercontent.com/zoocityboy/zoo_brand/main/styles/README/zoocityboy_light.png#gh-dark-mode-only
[zoocityboy_link]: https://github.com/zoocityboy
[zoocityboy_link_dark]: https://github.com/zoocityboy#gh-dark-mode-only
[zoocityboy_link_light]: https://github.com/zoocityboy#gh-light-mode-only
import 'package:manifest_dart_sdk/manifest_dart_sdk.dart';

void main() async {
  // Initialize the client
  final client = Manifest('http://localhost:1111');

  // Example 1: Working with singles
  try {
    print('Fetching single entity...');
    // Get a single entity
    var about = await client.single('about').get<Map<String, dynamic>>();
    print('About page: ${about['title']}');

    // Update a single entity
    var updated = await client.single('about').update<Map<String, dynamic>>({
      'title': 'Updated About Page',
      'content': 'This is the updated about page content.',
    });
    print('Updated: ${updated['title']}');
  } on NotFoundException catch (e) {
    print('The requested single entity was not found: ${e.message}');
  } on ValidationException catch (e) {
    print('Validation error: ${e.message}');
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
  } catch (e) {
    print('Unexpected error: $e');
  }

  // Example 2: Working with collections with improved error handling
  try {
    // Get a paginated list of posts
    try {
      var posts = await client.from('posts').find(page: 1, perPage: 10);
      print(
        'Found ${posts.total} posts. Showing page ${posts.currentPage} of ${posts.lastPage}',
      );
      for (var post in posts.data) {
        print('- ${post['title']}');
      }
    } on ValidationException catch (e) {
      print('Invalid pagination parameters: ${e.message}');
    } on AuthenticationException catch (e) {
      print('Not authorized to access posts: ${e.message}');
    }

    try {
      // Get a single post by ID - with proper error handling for not found
      var post = await client.from('posts').findOneById(1);
      print('Post #1: ${post['title']}');
    } on NotFoundException catch (e) {
      print('Post not found: ${e.message}');
    }

    try {
      // Create a new post - with validation error handling
      var newPost = await client.from('posts').create({
        'title': 'New Post',
        'content': 'This is a new post created with the Dart SDK.',
      });
      print('Created post with ID: ${newPost['id']}');
    } on ValidationException catch (e) {
      print('Post creation validation error:');
      if (e.validationErrors != null) {
        e.validationErrors!.forEach((field, errors) {
          print('  - $field: ${errors.join(', ')}');
        });
      }
    } on AuthenticationException catch (e) {
      print('Not authorized to create posts: ${e.message}');
    }

    try {
      // Update a post
      var updatedPost = await client.from('posts').update(1, {
        'title': 'Updated Post',
        'content': 'This post was updated with the Dart SDK.',
      });
      print('Updated post: ${updatedPost['title']}');
    } on NotFoundException catch (e) {
      print('Post to update not found: ${e.message}');
    } on ValidationException catch (e) {
      print('Post update validation error: ${e.message}');
    }

    try {
      // Partially update a post
      var patchedPost = await client.from('posts').patch(1, {
        'title': 'Patched Post',
      });
      print('Patched post: ${patchedPost['title']}');
    } on NotFoundException catch (e) {
      print('Post to patch not found: ${e.message}');
    }

    try {
      // Delete a post
      var deletedId = await client.from('posts').delete(2);
      print('Deleted post with ID: $deletedId');
    } on NotFoundException catch (e) {
      print('Post to delete not found: ${e.message}');
    } on AuthenticationException catch (e) {
      print('Not authorized to delete this post: ${e.message}');
    }
  } on ServerException catch (e) {
    print('Server error while working with collections: ${e.message}');
  } on NetworkException catch (e) {
    print('Network error while working with collections: ${e.message}');
    print('Original exception: ${e.originalException}');
  } catch (e) {
    print('Unexpected error with collections: $e');
  }

  // Example 3: Authentication with improved error handling
  try {
    // Login
    try {
      await client.login('admins', 'admin@manifest.build', 'admin');
      print('Login successful');

      // Get the current user
      var user = await client.from('users').me();
      print('Current user: ${user['email']}');

      // Logout
      client.logout();
      print('Logged out');
    } on AuthenticationException catch (e) {
      print('Authentication failed: ${e.message}');
      print('Status code: ${e.statusCode}');

      // You can access additional error information
      if (e.errorData != null) {
        print('Error details: ${e.errorData}');
      }
    }

    // Signup with error handling
    try {
      await client.signup('users', 'newuser@example.com', 'password123');
      print('Signup successful');
    } on ValidationException catch (e) {
      print('Signup validation error: ${e.message}');
      if (e.validationErrors != null) {
        // Detailed field validation errors
        e.validationErrors!.forEach((field, errors) {
          print('  - $field: ${errors.join(', ')}');
        });
      }
    } on AuthenticationException catch (e) {
      print('Signup authentication error: ${e.message}');
    }
  } on ServerException catch (e) {
    print('Server error (${e.statusCode}): ${e.message}');
  } on NetworkException catch (e) {
    print('Network connectivity issue: ${e.message}');
  } catch (e) {
    print('Unexpected error: $e');
  }
}

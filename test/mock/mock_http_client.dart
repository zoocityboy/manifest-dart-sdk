// ignore_for_file: unused_local_variable

import 'dart:convert';

import 'package:http/http.dart';
import 'package:http/testing.dart';

/// Creates a mock HTTP client that returns predefined responses
MockClient createMockClient() {
  return MockClient((request) async {
    final uri = request.url;
    final path = uri.path;

    // Single entity endpoints
    if (path.contains('/api/singles/')) {
      return _handleSingleEndpoints(request);
    }

    // Collection entity endpoints
    if (path.contains('/api/collections/')) {
      return _handleCollectionEndpoints(request);
    }

    // Auth endpoints
    if (path.contains('/api/auth/')) {
      return _handleAuthEndpoints(request);
    }

    // Upload endpoints
    if (path.contains('/api/upload/')) {
      return _handleUploadEndpoints(request);
    }

    // Default fallback
    return Response('{"error": "Not found"}', 404);
  });
}

/// Handle single entity endpoints
Response _handleSingleEndpoints(Request request) {
  final parts = request.url.path.split('/');
  final slug = parts.last;

  if (request.method == 'GET') {
    return Response(json.encode({'title': 'About Page', 'content': 'This is the about page content.'}), 200);
  } else if (request.method == 'PUT') {
    final requestBody = json.decode(request.body);
    return Response(json.encode({...requestBody, 'updatedAt': DateTime.now().toIso8601String()}), 200);
  } else if (request.method == 'PATCH') {
    final requestBody = json.decode(request.body);
    return Response(
      json.encode({
        'title': 'About Page',
        'content': 'This is the about page content.',
        ...requestBody,
        'updatedAt': DateTime.now().toIso8601String(),
      }),
      200,
    );
  }

  return Response('{"error": "Method not allowed"}', 405);
}

/// Handle collection entity endpoints
Response _handleCollectionEndpoints(Request request) {
  final parts = request.url.path.split('/');
  final slug = parts[parts.length - 2 == 'collections' ? parts.length - 1 : parts.length - 2];
  final hasId = parts.length > 3 && parts[parts.length - 2] != 'collections';
  final id = hasId ? parts.last : null;

  // GET collection list
  if (request.method == 'GET' && !hasId) {
    final page = int.tryParse(request.url.queryParameters['page'] ?? '1') ?? 1;
    final perPage = int.tryParse(request.url.queryParameters['perPage'] ?? '10') ?? 10;

    List<Map<String, dynamic>> items = [];
    for (int i = 1; i <= 15; i++) {
      items.add({'id': i, 'title': 'Item $i', 'content': 'Content for item $i'});
    }

    final startIndex = (page - 1) * perPage;
    final endIndex = startIndex + perPage > items.length ? items.length : startIndex + perPage;
    final pageItems = startIndex < items.length ? items.sublist(startIndex, endIndex) : [];

    return Response(
      json.encode({
        'data': pageItems,
        'current_page': page,
        'last_page': (items.length / perPage).ceil(),
        'per_page': perPage,
        'total': items.length,
        'from': startIndex + 1,
        'to': endIndex,
      }),
      200,
    );
  }

  // GET single item
  if (request.method == 'GET' && hasId) {
    final idNum = int.parse(id!);
    return Response(json.encode({'id': idNum, 'title': 'Item $idNum', 'content': 'Content for item $idNum'}), 200);
  }

  // POST create item
  if (request.method == 'POST') {
    final requestBody = json.decode(request.body);
    return Response(json.encode({'id': 16, ...requestBody, 'createdAt': DateTime.now().toIso8601String()}), 201);
  }

  // PUT update item
  if (request.method == 'PUT' && hasId) {
    final requestBody = json.decode(request.body);
    final idNum = int.parse(id!);
    return Response(json.encode({'id': idNum, ...requestBody, 'updatedAt': DateTime.now().toIso8601String()}), 200);
  }

  // PATCH update item
  if (request.method == 'PATCH' && hasId) {
    final requestBody = json.decode(request.body);
    final idNum = int.parse(id!);
    return Response(
      json.encode({
        'id': idNum,
        'title': 'Item $idNum',
        'content': 'Content for item $idNum',
        ...requestBody,
        'updatedAt': DateTime.now().toIso8601String(),
      }),
      200,
    );
  }

  // DELETE item
  if (request.method == 'DELETE' && hasId) {
    return Response('', 204);
  }

  return Response('{"error": "Method not allowed"}', 405);
}

/// Handle authentication endpoints
Response _handleAuthEndpoints(Request request) {
  final parts = request.url.path.split('/');

  // Login endpoint
  if (parts.last == 'login') {
    final requestBody = json.decode(request.body);
    final email = requestBody['email'];
    final password = requestBody['password'];

    if (email == 'user@example.com' && password == 'password123') {
      return Response(json.encode({'token': 'mock_jwt_token_for_testing'}), 200);
    } else {
      return Response(json.encode({'error': 'Invalid credentials'}), 401);
    }
  }

  // Signup endpoint
  if (parts.last == 'signup') {
    final requestBody = json.decode(request.body);
    return Response(json.encode({'token': 'mock_jwt_token_for_signup'}), 201);
  }

  // Me endpoint
  if (parts.last == 'me') {
    final authHeader = request.headers['Authorization'];

    if (authHeader != null && authHeader.startsWith('Bearer ')) {
      return Response(json.encode({'email': 'user@example.com', 'id': 1, 'name': 'Test User'}), 200);
    } else {
      return Response(json.encode({'error': 'Unauthorized'}), 401);
    }
  }

  return Response('{"error": "Not found"}', 404);
}

/// Handle upload endpoints
Response _handleUploadEndpoints(Request request) {
  if (request.url.path.contains('upload/file')) {
    return Response(json.encode({'path': 'uploads/files/mock-file.pdf'}), 200);
  }

  if (request.url.path.contains('upload/image')) {
    return Response(
      json.encode({
        'thumbnail': 'uploads/images/thumbnail/mock-image.jpg',
        'small': 'uploads/images/small/mock-image.jpg',
        'medium': 'uploads/images/medium/mock-image.jpg',
        'large': 'uploads/images/large/mock-image.jpg',
      }),
      200,
    );
  }

  return Response('{"error": "Not found"}', 404);
}

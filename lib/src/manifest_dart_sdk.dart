import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:universal_io/io.dart' show SocketException, HttpException;

import 'base_sdk.dart';
import 'exceptions.dart';
import 'paginator.dart';

part 'single_entity.dart';

/// Manifest SDK Client
class Manifest extends BaseSDK {
  /// The Manifest backend base URL (Without ending slash)
  String baseUrl = 'http://localhost:1111/api';

  /// The headers of the request
  final Map<String, String> _headers = {'Content-Type': 'application/json'};

  /// Create a new instance of the client.
  ///
  /// [baseUrl] The Manifest backend URL address (Without ending slash). Default: http://localhost:1111
  Manifest([String? baseUrl]) {
    if (baseUrl != null) {
      this.baseUrl = '$baseUrl/api';
    }
  }

  /// Set the slug of the single entity to query.
  ///
  /// [slug] The slug of the single entity to query.
  ///
  /// Returns an object containing the methods to get and update the single entity.
  ///
  /// Example: client.single('about').get()
  /// Example: client.single('home').update({ 'title': 'New title' })
  SingleEntity single(String slug) {
    this.slug = slug;
    isSingleEntity = true;
    queryParams = {};

    return SingleEntity(this);
  }

  /// Set the entity to query.
  ///
  /// [slug] The slug of the entity to query.
  ///
  /// Returns the client instance to chain methods.
  ///
  /// Example: client.from('users').find()
  /// Example: client.from('products').create({'name': 'Product 1'})
  Manifest from(String slug) {
    this.slug = slug;
    isSingleEntity = false;
    queryParams = {};
    return this;
  }

  /// Get the paginated list of items of the entity.
  ///
  /// [paginationParams] - Optional pagination parameters.
  ///
  /// Returns a Future that resolves a Paginator object.
  Future<Paginator<T>> find<T>({int? page, int? perPage, T Function(Map<String, dynamic>)? fromJson}) async {
    final response = await _fetch(
      path: '/collections/$slug',
      queryParams: {
        ...queryParams,
        if (page != null) 'page': page.toString(),
        if (perPage != null) 'perPage': perPage.toString(),
      },
    );

    if (fromJson != null) {
      return Paginator<T>.fromJson(response, (item) => fromJson(item));
    }

    // Default case for dynamic objects
    return Paginator<T>.fromJson(response, (item) => item as T);
  }

  /// Get an item of the entity.
  ///
  /// [id] The id of the item to get.
  ///
  /// Returns the item of the entity.
  /// Example: client.from('cats').findOneById(1);
  Future<T> findOneById<T>(int id) async {
    final response = await _fetch(path: '/collections/$slug/$id', queryParams: null);

    return response as T;
  }

  /// Create an item of the entity.
  ///
  /// [itemDto] The data of the item to create.
  ///
  /// Returns the created item.
  Future<T> create<T>(Map<String, dynamic> itemDto) async {
    final response = await _fetch(path: '/collections/$slug', method: 'POST', body: itemDto);

    return response as T;
  }

  /// Update an item of the entity doing a full replace.
  ///
  /// [id] The id of the item to update.
  /// [itemDto] The data of the item to update.
  ///
  /// Returns the updated item.
  /// Example: client.from('cats').update(1, { 'name': 'updated name' });
  Future<T> update<T>(int id, Map<String, dynamic> itemDto) async {
    final response = await _fetch(path: '/collections/$slug/$id', method: 'PUT', body: itemDto);

    return response as T;
  }

  /// Partially update an item of the entity.
  ///
  /// [id] The id of the item to update.
  /// [itemDto] The data of the item to update.
  ///
  /// Returns the updated item.
  /// Example: client.from('cats').patch(1, { 'name': 'updated name' });
  Future<T> patch<T>(int id, Map<String, dynamic> itemDto) async {
    final response = await _fetch(path: '/collections/$slug/$id', method: 'PATCH', body: itemDto);

    return response as T;
  }

  /// Delete an item of the entity.
  ///
  /// [id] The id of the item to delete.
  ///
  /// Returns the id of the deleted item.
  /// Example: client.from('cats').delete(1);
  Future<int> delete(int id) async {
    await _fetch(path: '/collections/$slug/$id', method: 'DELETE');

    return id;
  }

  /// Login as any authenticable entity.
  ///
  /// [entitySlug] The slug of the entity to login as.
  /// [email] The email of the entity to login as.
  /// [password] The password of the entity to login as.
  ///
  /// Returns true if the login was successful.
  ///
  /// Throws:
  /// - [AuthenticationException] if the credentials are invalid
  /// - [ValidationException] if the request data is invalid
  /// - Other exceptions from [_fetch] for network or server errors
  Future<bool> login(String entitySlug, String email, String password) async {
    final response = await _fetch(
      path: '/auth/$entitySlug/login',
      method: 'POST',
      body: {'email': email, 'password': password},
    );

    if (response['token'] == null) {
      throw AuthenticationException(
        'Authentication failed: No token received',
        401,
        json.encode(response),
        errorData: response is Map<String, dynamic> ? response : null,
      );
    }

    _headers['Authorization'] = 'Bearer ${response['token']}';
    return true;
  }

  /// Logout as any authenticable entity.
  void logout() {
    _headers.remove('Authorization');
  }

  /// Signup as any authenticable entity but Admin and login.
  ///
  /// [entitySlug] The slug of the entity to signup as.
  /// [email] The email of the entity to signup as.
  /// [password] The password of the entity to signup as.
  ///
  /// Returns true if the signup was successful.
  ///
  /// Throws:
  /// - [ValidationException] if the signup data is invalid (e.g., email already exists)
  /// - [AuthenticationException] if there's an authentication issue
  /// - Other exceptions from [_fetch] for network or server errors
  Future<bool> signup(String entitySlug, String email, String password) async {
    final response = await _fetch(
      path: '/auth/$entitySlug/signup',
      method: 'POST',
      body: {'email': email, 'password': password},
    );

    if (response['token'] == null) {
      throw AuthenticationException(
        'Signup failed: No token received',
        401,
        json.encode(response),
        errorData: response is Map<String, dynamic> ? response : null,
      );
    }

    _headers['Authorization'] = 'Bearer ${response['token']}';
    return true;
  }

  /// Gets the current logged in user (me).
  ///
  /// Returns the current logged in user.
  /// Example: client.from('users').me();
  Future<Map<String, dynamic>> me() async {
    final response = await _fetch(path: '/auth/$slug/me');

    return response;
  }

  /// Fetch data from the API
  ///
  /// This method handles all HTTP requests to the Manifest API and properly processes errors.
  /// It throws appropriate exceptions based on the HTTP response status code.
  ///
  /// Throws:
  /// - [NetworkException] for connectivity issues
  /// - [AuthenticationException] for 401/403 responses
  /// - [ValidationException] for 422 responses with validation errors
  /// - [NotFoundException] for 404 responses
  /// - [RateLimitException] for 429 responses
  /// - [ServerException] for 5xx responses
  /// - [ApiException] for other error responses
  Future<dynamic> _fetch({
    required String path,
    String method = 'GET',
    dynamic body,
    Map<String, String>? queryParams,
  }) async {
    final uri = Uri.parse(baseUrl + path);
    final url = uri.replace(queryParameters: queryParams);

    http.Response response;
    final logData =
        StringBuffer()
          ..writeln('Request URL: $url')
          ..writeln('Request Method: $method')
          ..writeln('Request Headers: $_headers');
    if (body != null) {
      logData.writeln('Request Body: \n${json.encode(body)}');
    }
    print(logData.toString());
    try {
      switch (method) {
        case 'GET':
          response = await http.get(url, headers: _headers);
          break;
        case 'POST':
          response = await http.post(url, headers: _headers, body: body != null ? json.encode(body) : null);
          break;
        case 'PUT':
          response = await http.put(url, headers: _headers, body: body != null ? json.encode(body) : null);
          break;
        case 'PATCH':
          response = await http.patch(url, headers: _headers, body: body != null ? json.encode(body) : null);
          break;
        case 'DELETE':
          response = await http.delete(url, headers: _headers);
          break;
        default:
          throw ArgumentError('Invalid HTTP method: $method');
      }
    } on SocketException catch (e) {
      throw NetworkException(
        'Network error: Unable to connect to the server. Please check your internet connection.',
        e,
        StackTrace.current,
      );
    } on HttpException catch (e) {
      throw NetworkException('HTTP error: ${e.message}', e, StackTrace.current);
    } catch (e) {
      throw NetworkException('Unknown network error: ${e.toString()}', e, StackTrace.current);
    }

    // Handle different response status codes
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        if (response.body.isEmpty) {
          return {};
        }
        return json.decode(response.body);
      } catch (e) {
        throw ApiException(
          'Failed to parse response body: ${e.toString()}',
          response.statusCode,
          response.body,
          headers: response.headers,
          stackTrace: StackTrace.current,
        );
      }
    } else {
      // Handle error responses based on status code
      switch (response.statusCode) {
        case 401:
        case 403:
          throw AuthenticationException.fromResponse(response);
        case 404:
          throw NotFoundException.fromResponse(response);

        case 422:
          throw ValidationException.fromResponse(response);

        case 429:
          throw RateLimitException.fromResponse(response);

        case >= 500 && < 600:
          throw ServerException.fromResponse(response);

        default:
          throw ApiException.fromResponse(response);
      }
    }
  }

  /// Upload a file to the entity.
  ///
  /// [property] The property of the entity to upload the file to.
  /// [file] The file data to upload.
  /// [filename] The name of the file.
  ///
  /// Returns the path of the uploaded file.
  ///
  /// Throws:
  /// - [NetworkException] for connectivity issues
  /// - [AuthenticationException] if not authenticated or not authorized
  /// - [ValidationException] for invalid file data
  /// - [ApiException] for other API errors
  Future<Map<String, dynamic>> upload(String property, Uint8List file, String filename) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload/file'));

    if (_headers.containsKey('Authorization')) {
      request.headers['Authorization'] = _headers['Authorization']!;
    }

    final fileType = _getFileType(filename);

    final multipartFile = http.MultipartFile.fromBytes(
      'file',
      file,
      filename: filename,
      contentType: MediaType(fileType, ''),
    );

    request.files.add(multipartFile);
    request.fields['entity'] = slug;
    request.fields['property'] = property;

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Handle response status codes
      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          return json.decode(response.body) as Map<String, dynamic>;
        } catch (e) {
          throw ApiException(
            'Failed to parse upload response: ${e.toString()}',
            response.statusCode,
            response.body,
            stackTrace: StackTrace.current,
          );
        }
      } else {
        // Handle error responses based on status code
        switch (response.statusCode) {
          case 401:
          case 403:
            throw AuthenticationException.fromResponse(response);

          case 422:
            throw ValidationException.fromResponse(response);

          default:
            throw ApiException.fromResponse(response);
        }
      }
    } on SocketException catch (e) {
      throw NetworkException('Network error during file upload: ${e.message}', e, StackTrace.current);
    } catch (e) {
      if (e is ManifestException) {
        rethrow;
      }
      throw ApiException('File upload error: ${e.toString()}', 0, '', stackTrace: StackTrace.current);
    }
  }

  /// Upload an image to the entity.
  ///
  /// [property] The property of the entity to upload the image to.
  /// [image] The image data to upload.
  /// [filename] The name of the image file.
  ///
  /// Returns an object containing the path of the uploaded image in different sizes.
  ///
  /// Throws:
  /// - [NetworkException] for connectivity issues
  /// - [AuthenticationException] if not authenticated or not authorized
  /// - [ValidationException] for invalid image data
  /// - [ApiException] for other API errors
  Future<Map<String, dynamic>> uploadImage(String property, Uint8List image, String filename) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload/image'));

    if (_headers.containsKey('Authorization')) {
      request.headers['Authorization'] = _headers['Authorization']!;
    }

    final fileType = _getImageType(filename);

    final multipartFile = http.MultipartFile.fromBytes(
      'image',
      image,
      filename: filename,
      contentType: MediaType('image', fileType),
    );

    request.files.add(multipartFile);
    request.fields['entity'] = slug;
    request.fields['property'] = property;

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Handle response status codes
      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          return json.decode(response.body) as Map<String, dynamic>;
        } catch (e) {
          throw ApiException(
            'Failed to parse image upload response: ${e.toString()}',
            response.statusCode,
            response.body,
            stackTrace: StackTrace.current,
          );
        }
      } else {
        // Handle error responses based on status code
        switch (response.statusCode) {
          case 401:
          case 403:
            throw AuthenticationException.fromResponse(response);

          case 422:
            throw ValidationException.fromResponse(response);

          default:
            throw ApiException.fromResponse(response);
        }
      }
    } on SocketException catch (e) {
      throw NetworkException('Network error during image upload: ${e.message}', e, StackTrace.current);
    } catch (e) {
      if (e is ManifestException) {
        rethrow;
      }
      throw ApiException('Image upload error: ${e.toString()}', 0, '', stackTrace: StackTrace.current);
    }
  }

  /// Helper that returns the absolute URL of the image.
  ///
  /// [image] The image object containing the different sizes of the image.
  /// [size] The size of the image to get the URL for.
  ///
  /// Returns The absolute URL of the image.
  String imageUrl(Map<String, dynamic> image, String size) {
    return '${baseUrl.replaceAll(RegExp(r'/api$'), '')}/storage/${image[size]}';
  }

  // Helper to determine file content type
  String _getFileType(String filename) {
    if (filename.endsWith('.pdf')) return 'application/pdf';
    if (filename.endsWith('.doc') || filename.endsWith('.docx')) return 'application/msword';
    if (filename.endsWith('.xls') || filename.endsWith('.xlsx')) return 'application/vnd.ms-excel';
    if (filename.endsWith('.txt')) return 'text/plain';
    return 'application/octet-stream';
  }

  // Helper to determine image content type
  String _getImageType(String filename) {
    if (filename.endsWith('.png')) return 'png';
    if (filename.endsWith('.jpg') || filename.endsWith('.jpeg')) return 'jpeg';
    if (filename.endsWith('.gif')) return 'gif';
    if (filename.endsWith('.webp')) return 'webp';
    if (filename.endsWith('.svg')) return 'svg+xml';
    return 'jpeg'; // default
  }
}

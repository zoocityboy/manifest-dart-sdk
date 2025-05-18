import 'package:manifest_dart_sdk/manifest-dart-sdk.dart';
import 'package:manifest_dart_sdk/src/paginator.dart';
import 'package:test/test.dart';

void main() {
  late Manifest client;

  setUp(() {
    // Create a client with a mock HTTP client
    client = Manifest('http://localhost:1111');

    // Here we would inject the mock HTTP client
    // This is not possible with our current implementation since the client creates its own HTTP client
    // In a real-world scenario, you'd want to refactor the Manifest class to accept an HTTP client in its constructor
  });

  group('Manifest API', () {
    test('Default URL is correctly set', () {
      expect(client.baseUrl, equals('http://localhost:1111/api'));
    });

    test('Custom URL is correctly set', () {
      final customClient = Manifest('https://example.com');
      expect(customClient.baseUrl, equals('https://example.com/api'));
    });
  });

  group('Single Entity Operations', () {
    test('Calling single() sets correct properties', () {
      client.single('about');
      expect(client.slug, equals('about'));
      expect(client.isSingleEntity, isTrue);
      expect(client.queryParams, equals({}));
    });
  });

  group('Collection Entity Operations', () {
    test('Calling from() sets correct properties', () {
      final result = client.from('posts');
      expect(client.slug, equals('posts'));
      expect(client.isSingleEntity, isFalse);
      expect(client.queryParams, equals({}));
      expect(result, same(client)); // Should return the same instance
    });
  });

  group('Pagination', () {
    test('Empty paginator is initialized correctly', () {
      final paginator = Paginator<String>.empty();
      expect(paginator.data, isEmpty);
      expect(paginator.currentPage, equals(1));
      expect(paginator.lastPage, equals(1));
      expect(paginator.from, equals(0));
      expect(paginator.to, equals(0));
      expect(paginator.total, equals(0));
      expect(paginator.perPage, equals(10));
    });

    test('Paginator correctly parses JSON', () {
      final json = {
        'data': [
          {'id': 1, 'name': 'Item 1'},
          {'id': 2, 'name': 'Item 2'},
        ],
        'current_page': 2,
        'last_page': 5,
        'from': 11,
        'to': 20,
        'total': 50,
        'per_page': 10,
      };

      final paginator = Paginator<Map<String, dynamic>>.fromJson(
        json,
        (item) => item as Map<String, dynamic>,
      );

      expect(paginator.data.length, equals(2));
      expect(paginator.data[0]['id'], equals(1));
      expect(paginator.data[1]['name'], equals('Item 2'));
      expect(paginator.currentPage, equals(2));
      expect(paginator.lastPage, equals(5));
      expect(paginator.from, equals(11));
      expect(paginator.to, equals(20));
      expect(paginator.total, equals(50));
      expect(paginator.perPage, equals(10));
    });
  });

  group('Helper Methods', () {
    test('imageUrl formats URL correctly', () {
      final imageData = {
        'thumbnail': 'path/to/thumb.jpg',
        'small': 'path/to/small.jpg',
        'medium': 'path/to/medium.jpg',
        'large': 'path/to/large.jpg',
      };

      final thumbUrl = client.imageUrl(imageData, 'thumbnail');
      final mediumUrl = client.imageUrl(imageData, 'medium');

      expect(
        thumbUrl,
        equals('http://localhost:1111/storage/path/to/thumb.jpg'),
      );
      expect(
        mediumUrl,
        equals('http://localhost:1111/storage/path/to/medium.jpg'),
      );
    });
  });
}

import 'package:manifest_dart_sdk/manifest_dart_sdk.dart';
import 'package:manifest_dart_sdk/src/paginator.dart';
import 'package:test/test.dart';

void main() {
  group('Manifest SDK initialization', () {
    test('Default URL', () {
      final client = Manifest();
      expect(client.baseUrl, equals('http://localhost:1111/api'));
    });

    test('Custom URL', () {
      final client = Manifest('https://custom-url.com');
      expect(client.baseUrl, equals('https://custom-url.com/api'));
    });
  });

  group('Single Entity', () {
    final client = Manifest();

    test('single() sets properties correctly', () {
      client.single('about');
      expect(client.slug, equals('about'));
      expect(client.isSingleEntity, isTrue);
      expect(client.queryParams, equals({}));
    });
  });

  group('Collection Entity', () {
    final client = Manifest();

    test('from() sets properties correctly', () {
      final result = client.from('posts');
      expect(client.slug, equals('posts'));
      expect(client.isSingleEntity, isFalse);
      expect(client.queryParams, equals({}));
      expect(result, equals(client)); // Method is chainable
    });
  });

  group('Paginator', () {
    test('empty paginator has default values', () {
      final paginator = Paginator<Map<String, dynamic>>.empty();
      expect(paginator.data, isEmpty);
      expect(paginator.currentPage, equals(1));
      expect(paginator.lastPage, equals(1));
      expect(paginator.total, equals(0));
      expect(paginator.perPage, equals(10));
    });
  });

  group('Image URL helper', () {
    final client = Manifest('http://localhost:1111');

    test('imageUrl formats URL correctly', () {
      final imageUrl = client.imageUrl({'thumbnail': 'path/to/image.jpg'}, 'thumbnail');
      expect(imageUrl, equals('http://localhost:1111/storage/path/to/image.jpg'));
    });
  });
}

/// Class representing a paginated response
class Paginator<T> {
  final List<T> data;
  final int currentPage;
  final int lastPage;
  final int total;
  final int perPage;
  final int from;
  final int to;

  /// Constructor
  Paginator({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.perPage,
    required this.from,
    required this.to,
  });

  /// Factory constructor to create a Paginator from JSON
  factory Paginator.fromJson(Map<String, dynamic> json, T Function(dynamic) fromJson) {
    final items = (json['data'] as List).map((item) => fromJson(item)).toList();

    return Paginator<T>(
      data: items,
      currentPage: json['current_page'] ?? 1,
      lastPage: json['last_page'] ?? 1,
      total: json['total'] ?? 0,
      perPage: json['per_page'] ?? 10,
      from: json['from'] ?? 0,
      to: json['to'] ?? 0,
    );
  }

  /// Factory constructor to create an empty Paginator
  factory Paginator.empty() {
    return Paginator<T>(data: [], currentPage: 1, lastPage: 1, total: 0, perPage: 10, from: 0, to: 0);
  }
}

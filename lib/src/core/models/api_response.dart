class ApiEnvelope<T> {
  ApiEnvelope({
    required this.success,
    required this.message,
    required this.data,
  });

  factory ApiEnvelope.fromJson(
    Map<String, dynamic> json,
    T Function(Object? raw) decoder,
  ) {
    return ApiEnvelope<T>(
      success: json['success'] == true,
      message: (json['message'] ?? '').toString(),
      data: decoder(json['data']),
    );
  }

  final bool success;
  final String message;
  final T data;
}

class PagedResponse<T> {
  PagedResponse({
    required this.items,
    required this.page,
    required this.hasNext,
  });

  factory PagedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> item) decoder,
  ) {
    final rawItems = json['items'];
    final parsedItems = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map((item) => decoder(Map<String, dynamic>.from(item)))
            .toList()
        : <T>[];

    return PagedResponse<T>(
      items: parsedItems,
      page: (json['page'] as num?)?.toInt() ?? 0,
      hasNext: json['hasNext'] == true,
    );
  }

  final List<T> items;
  final int page;
  final bool hasNext;
}

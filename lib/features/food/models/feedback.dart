class Feedback {
  final String orderId;
  final String vendorId;
  final List<String> itemIds;
  final int rating;
  final String? comment;
  final DateTime at;

  const Feedback({
    required this.orderId,
    required this.vendorId,
    required this.itemIds,
    required this.rating,
    this.comment,
    required this.at,
  });

  Feedback copyWith({
    String? orderId,
    String? vendorId,
    List<String>? itemIds,
    int? rating,
    String? comment,
    DateTime? at,
  }) {
    return Feedback(
      orderId: orderId ?? this.orderId,
      vendorId: vendorId ?? this.vendorId,
      itemIds: itemIds ?? this.itemIds,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      at: at ?? this.at,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Feedback &&
          runtimeType == other.runtimeType &&
          orderId == other.orderId &&
          vendorId == other.vendorId &&
          rating == other.rating &&
          comment == other.comment &&
          at == other.at;

  @override
  int get hashCode => Object.hash(orderId, vendorId, rating, comment, at);

  @override
  String toString() =>
      'Feedback(orderId: $orderId, vendorId: $vendorId, rating: $rating, comment: $comment, at: $at)';
}

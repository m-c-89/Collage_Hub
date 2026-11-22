enum RoomMarkKind {
  active,
  pending,
}

class RoomMark {
  final int? stopNumber;
  final RoomMarkKind kind;

  const RoomMark({
    this.stopNumber,
    required this.kind,
  });

  bool get isActive => kind == RoomMarkKind.active;
  bool get isPending => kind == RoomMarkKind.pending;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoomMark &&
          runtimeType == other.runtimeType &&
          stopNumber == other.stopNumber &&
          kind == other.kind;

  @override
  int get hashCode => Object.hash(stopNumber, kind);

  @override
  String toString() => 'RoomMark(stopNumber: $stopNumber, kind: $kind)';
}

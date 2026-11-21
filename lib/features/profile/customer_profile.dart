class CustomerProfile {
  final String id;
  final String fullName;
  final String mobileNumber;

  const CustomerProfile({
    this.id = 'default-customer',
    required this.fullName,
    required this.mobileNumber,
  });

  CustomerProfile copyWith({
    String? id,
    String? fullName,
    String? mobileNumber,
  }) {
    return CustomerProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      mobileNumber: mobileNumber ?? this.mobileNumber,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerProfile &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          fullName == other.fullName &&
          mobileNumber == other.mobileNumber;

  @override
  int get hashCode => Object.hash(id, fullName, mobileNumber);

  @override
  String toString() {
    return 'CustomerProfile(id: $id, fullName: $fullName, mobileNumber: $mobileNumber)';
  }
}

class CustomerProfile {
  final String fullName;
  final String mobileNumber;

  const CustomerProfile({
    required this.fullName,
    required this.mobileNumber,
  });

  CustomerProfile copyWith({
    String? fullName,
    String? mobileNumber,
  }) {
    return CustomerProfile(
      fullName: fullName ?? this.fullName,
      mobileNumber: mobileNumber ?? this.mobileNumber,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerProfile &&
          runtimeType == other.runtimeType &&
          fullName == other.fullName &&
          mobileNumber == other.mobileNumber;

  @override
  int get hashCode => Object.hash(fullName, mobileNumber);

  @override
  String toString() {
    return 'CustomerProfile(fullName: $fullName, mobileNumber: $mobileNumber)';
  }
}

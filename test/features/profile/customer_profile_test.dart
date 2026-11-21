import 'package:flutter_test/flutter_test.dart';
import 'package:college_canteen/features/profile/customer_profile.dart';
import 'package:college_canteen/features/profile/profile_provider.dart';

void main() {
  group('CustomerProfile Model Tests', () {
    test('creates and holds profile fields correctly', () {
      const profile = CustomerProfile(
        fullName: 'Aarav Sharma',
        mobileNumber: '9876543210',
      );

      expect(profile.fullName, 'Aarav Sharma');
      expect(profile.mobileNumber, '9876543210');
    });

    test('copyWith works as expected', () {
      const profile = CustomerProfile(
        fullName: 'Aarav Sharma',
        mobileNumber: '9876543210',
      );

      final updated = profile.copyWith(fullName: 'Aarav Verma');
      expect(updated.fullName, 'Aarav Verma');
      expect(updated.mobileNumber, '9876543210');
    });

    test('equality and hashCode work properly', () {
      const p1 = CustomerProfile(
        fullName: 'Aarav Sharma',
        mobileNumber: '9876543210',
      );
      const p2 = CustomerProfile(
        fullName: 'Aarav Sharma',
        mobileNumber: '9876543210',
      );

      expect(p1, equals(p2));
      expect(p1.hashCode, equals(p2.hashCode));
    });
  });

  group('ProfileProvider State Tests', () {
    late ProfileProvider provider;

    setUp(() {
      provider = ProfileProvider();
    });

    test('initial state has no profile', () {
      expect(provider.profile, isNull);
      expect(provider.hasProfile, isFalse);
    });

    test('save() updates profile, sets hasProfile to true, and notifies listeners', () {
      var notified = false;
      provider.addListener(() => notified = true);

      const profile = CustomerProfile(
        fullName: 'Priya Patel',
        mobileNumber: '8765432109',
      );

      provider.save(profile);

      expect(notified, isTrue);
      expect(provider.hasProfile, isTrue);
      expect(provider.profile?.fullName, 'Priya Patel');
      expect(provider.profile?.mobileNumber, '8765432109');
    });

    test('clear() resets profile to null', () {
      provider.save(
        const CustomerProfile(
          fullName: 'Priya Patel',
          mobileNumber: '8765432109',
        ),
      );
      expect(provider.hasProfile, isTrue);

      provider.clear();
      expect(provider.hasProfile, isFalse);
      expect(provider.profile, isNull);
    });
  });
}

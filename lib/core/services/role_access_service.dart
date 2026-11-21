import '../config/app_config.dart';
import '../domain/user_role.dart';

abstract interface class RoleAccessService {
  Future<bool> verifyInviteCode(UserRole role, String code);
}

class DemoRoleAccessService implements RoleAccessService {
  const DemoRoleAccessService();

  @override
  Future<bool> verifyInviteCode(UserRole role, String code) async {
    if (!AppConfig.kDemoMode) {
      return false;
    }

    final normalized = code.trim().toLowerCase();
    return switch (role) {
      UserRole.vendor =>
        normalized == AppConfig.demoVendorInviteCode.toLowerCase(),
      UserRole.deliveryPartner =>
        normalized == AppConfig.demoDeliveryInviteCode.toLowerCase(),
      UserRole.customer => false,
    };
  }
}

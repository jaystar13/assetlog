import 'enums.dart';

class SharedUser {
  final String id;
  final String name;
  final String email;
  final String avatar;
  PermissionLevel cashflowPermission;
  Map<String, PermissionLevel> assetPermissions;

  SharedUser({
    required this.id,
    required this.name,
    required this.email,
    required this.avatar,
    required this.cashflowPermission,
    required this.assetPermissions,
  });
}

import 'enums.dart';

class SharedUser {
  final String id;
  final String name;
  final String email;
  final String avatar;
  final PermissionLevel cashflowPermission;
  final Map<String, PermissionLevel> assetPermissions;

  const SharedUser({
    required this.id,
    required this.name,
    required this.email,
    required this.avatar,
    required this.cashflowPermission,
    required this.assetPermissions,
  });

  SharedUser copyWith({
    String? id,
    String? name,
    String? email,
    String? avatar,
    PermissionLevel? cashflowPermission,
    Map<String, PermissionLevel>? assetPermissions,
  }) {
    return SharedUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      cashflowPermission: cashflowPermission ?? this.cashflowPermission,
      assetPermissions: assetPermissions ?? this.assetPermissions,
    );
  }
}

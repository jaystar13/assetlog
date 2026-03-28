import 'enums.dart';

class Invitation {
  final String id;
  final String email;
  final String? name;
  final String? avatar;
  InvitationStatus status;
  final PermissionLevel cashflowPermission;
  final Map<String, PermissionLevel> assetPermissions;
  final String? message;
  final String sentDate;
  final String? expiryDate;
  final bool isIncoming;
  final String? inviterName;

  Invitation({
    required this.id,
    required this.email,
    this.name,
    this.avatar,
    required this.status,
    required this.cashflowPermission,
    required this.assetPermissions,
    this.message,
    required this.sentDate,
    this.expiryDate,
    required this.isIncoming,
    this.inviterName,
  });
}

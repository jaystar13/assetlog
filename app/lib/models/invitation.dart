import 'enums.dart';

class Invitation {
  final String id;
  final String email;
  final String? name;
  final String? avatar;
  final InvitationStatus status;
  final PermissionLevel cashflowPermission;
  final Map<String, PermissionLevel> assetPermissions;
  final String? message;
  final String sentDate;
  final String? expiryDate;
  final bool isIncoming;
  final String? inviterName;

  const Invitation({
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

  Invitation copyWith({
    String? id,
    String? email,
    String? name,
    String? avatar,
    InvitationStatus? status,
    PermissionLevel? cashflowPermission,
    Map<String, PermissionLevel>? assetPermissions,
    String? message,
    String? sentDate,
    String? expiryDate,
    bool? isIncoming,
    String? inviterName,
  }) {
    return Invitation(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      status: status ?? this.status,
      cashflowPermission: cashflowPermission ?? this.cashflowPermission,
      assetPermissions: assetPermissions ?? this.assetPermissions,
      message: message ?? this.message,
      sentDate: sentDate ?? this.sentDate,
      expiryDate: expiryDate ?? this.expiryDate,
      isIncoming: isIncoming ?? this.isIncoming,
      inviterName: inviterName ?? this.inviterName,
    );
  }
}

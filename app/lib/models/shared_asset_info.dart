class SharedAssetInfo {
  final String ownerName;
  final String ownerAvatar;
  final String ownerEmail;
  final String permissions;
  final int totalAssets;
  final int totalDebt;
  final int netWorth;
  final String lastUpdated;

  const SharedAssetInfo({
    required this.ownerName,
    required this.ownerAvatar,
    required this.ownerEmail,
    required this.permissions,
    required this.totalAssets,
    required this.totalDebt,
    required this.netWorth,
    required this.lastUpdated,
  });
}

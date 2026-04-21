class AssetItem {
  final String id;
  final String name;
  final String? note;
  final num currentValue;
  final num previousValue;
  final String lastUpdated;
  final String? editedBy;

  const AssetItem({
    required this.id,
    required this.name,
    this.note,
    required this.currentValue,
    required this.previousValue,
    required this.lastUpdated,
    this.editedBy,
  });

  num get change => currentValue - previousValue;

  double get changePercent {
    if (previousValue == 0) return 0;
    return ((currentValue - previousValue) / previousValue.abs()) * 100;
  }

  AssetItem copyWith({
    String? id,
    String? name,
    String? note,
    num? currentValue,
    num? previousValue,
    String? lastUpdated,
    String? editedBy,
  }) {
    return AssetItem(
      id: id ?? this.id,
      name: name ?? this.name,
      note: note ?? this.note,
      currentValue: currentValue ?? this.currentValue,
      previousValue: previousValue ?? this.previousValue,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      editedBy: editedBy ?? this.editedBy,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'note': note,
        'currentValue': currentValue,
        'previousValue': previousValue,
        'lastUpdated': lastUpdated,
        'editedBy': editedBy,
      };

  factory AssetItem.fromJson(Map<String, dynamic> json) => AssetItem(
        id: json['id'] as String,
        name: json['name'] as String,
        note: json['note'] as String?,
        currentValue: json['currentValue'] as num,
        previousValue: json['previousValue'] as num,
        lastUpdated: json['lastUpdated'] as String,
        editedBy: json['editedBy'] as String?,
      );
}

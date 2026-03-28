import 'package:flutter/material.dart';
import '../design_system/tokens/colors.dart';
import 'asset_item.dart';

class AssetGroup {
  final String id;
  final String name;
  final IconData icon;
  final String colorKey;
  final List<AssetItem> items;

  const AssetGroup({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorKey,
    required this.items,
  });

  num get totalValue => items.fold<num>(0, (sum, item) => sum + item.currentValue);
  num get totalPreviousValue =>
      items.fold<num>(0, (sum, item) => sum + item.previousValue);

  num get totalChange => totalValue - totalPreviousValue;

  double get changePercent {
    if (totalPreviousValue == 0) return 0;
    return ((totalValue - totalPreviousValue) / totalPreviousValue.abs()) * 100;
  }

  CategoryColors get colors => AppColors.category[colorKey]!;

  AssetGroup copyWith({
    String? id,
    String? name,
    IconData? icon,
    String? colorKey,
    List<AssetItem>? items,
  }) {
    return AssetGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      colorKey: colorKey ?? this.colorKey,
      items: items ?? this.items,
    );
  }
}

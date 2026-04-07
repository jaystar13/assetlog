import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/asset_item.dart';
import '../../models/asset_group.dart';
import '../../models/enums.dart';
import '../providers.dart';

class AssetNotifier extends AutoDisposeFamilyAsyncNotifier<List<AssetGroup>, String> {
  @override
  Future<List<AssetGroup>> build(String month) async {
    final service = ref.watch(assetServiceProvider);
    final rawAssets = await service.getAssets(month: month);
    return _groupAssets(rawAssets);
  }

  List<AssetGroup> _groupAssets(List<Map<String, dynamic>> rawAssets) {
    final Map<String, List<AssetItem>> grouped = {};

    for (final raw in rawAssets) {
      final categoryId = raw['categoryId'] as String;
      final history = raw['valueHistory'] as List<dynamic>? ?? [];
      final latestValue = history.isNotEmpty
          ? (history.first['value'] as num).toInt()
          : 0;

      final item = AssetItem(
        id: raw['id'] as String,
        name: raw['name'] as String,
        currentValue: latestValue,
        previousValue: 0,
        lastUpdated: history.isNotEmpty
            ? history.first['month'] as String
            : '',
      );

      grouped.putIfAbsent(categoryId, () => []).add(item);
    }

    return AssetCategoryType.values.map((cat) {
      final items = grouped[cat.id] ?? [];
      return AssetGroup(
        id: cat.id,
        name: cat.koreanName,
        icon: cat.icon,
        colorKey: cat.colorKey,
        items: items,
      );
    }).toList();
  }

  Future<void> addAsset({
    required String categoryId,
    required String name,
    int? initialValue,
  }) async {
    final service = ref.read(assetServiceProvider);
    final created = await service.createAsset(categoryId: categoryId, name: name);
    final assetId = created['id'] as String;
    developer.log('Asset created: $assetId, initialValue: $initialValue', name: 'AssetNotifier');

    if (initialValue != null && initialValue != 0) {
      try {
        await service.upsertHistory(assetId: assetId, month: arg, value: initialValue);
        developer.log('History saved: $assetId/$arg = $initialValue', name: 'AssetNotifier');
      } catch (e) {
        developer.log('History save FAILED: $e', name: 'AssetNotifier');
      }
    }

    ref.invalidateSelf();
  }

  Future<void> updateAssetValue({
    required String assetId,
    required String month,
    required int value,
  }) async {
    final service = ref.read(assetServiceProvider);
    await service.upsertHistory(assetId: assetId, month: month, value: value);
    ref.invalidateSelf();
  }

  Future<void> deleteAsset(String id) async {
    final service = ref.read(assetServiceProvider);
    await service.deleteAsset(id);
    ref.invalidateSelf();
  }
}

final assetNotifierProvider = AsyncNotifierProvider.autoDispose
    .family<AssetNotifier, List<AssetGroup>, String>(
  AssetNotifier.new,
);

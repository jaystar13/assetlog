import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/asset_item.dart';
import '../../models/asset_group.dart';
import '../../models/enums.dart';
import '../providers.dart';
import 'home_notifier.dart';

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
    List<String>? shareGroupIds,
  }) async {
    final service = ref.read(assetServiceProvider);
    final created = await service.createAsset(categoryId: categoryId, name: name, shareGroupIds: shareGroupIds);
    final assetId = created['id'] as String;
    final currentMonth = arg; // family parameter = YYYY-MM

    if (initialValue != null && initialValue != 0) {
      await service.upsertHistory(assetId: assetId, month: currentMonth, value: initialValue);
    }

    _invalidateAll();
  }

  Future<void> updateAssetValue({
    required String assetId,
    required String month,
    required int value,
  }) async {
    final service = ref.read(assetServiceProvider);
    await service.upsertHistory(assetId: assetId, month: month, value: value);
    _invalidateAll();
  }

  Future<void> closeAsset(String id) async {
    final service = ref.read(assetServiceProvider);
    await service.closeAsset(id);
    _invalidateAll();
  }

  Future<void> deleteAsset(String id) async {
    final service = ref.read(assetServiceProvider);
    await service.deleteAsset(id);
    _invalidateAll();
  }

  void _invalidateAll() {
    ref.invalidateSelf();
    ref.invalidate(homeNotifierProvider);
  }
}

final assetNotifierProvider = AsyncNotifierProvider.autoDispose
    .family<AssetNotifier, List<AssetGroup>, String>(
  AssetNotifier.new,
);

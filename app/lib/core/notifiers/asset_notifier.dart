import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/asset_item.dart';
import '../../models/asset_group.dart';
import '../../models/enums.dart';
import '../../services/asset_service.dart';
import '../providers.dart';

class AssetNotifier extends AutoDisposeAsyncNotifier<List<AssetGroup>> {
  late AssetService _service;

  @override
  Future<List<AssetGroup>> build() async {
    _service = ref.watch(assetServiceProvider);
    final rawAssets = await _service.getAssets();
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
        previousValue: 0, // 단일 히스토리만 가져오므로 이전값 없음
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
  }) async {
    await _service.createAsset(categoryId: categoryId, name: name);
    ref.invalidateSelf();
  }

  Future<void> updateAssetValue({
    required String assetId,
    required String month,
    required int value,
  }) async {
    await _service.upsertHistory(
      assetId: assetId,
      month: month,
      value: value,
    );
    ref.invalidateSelf();
  }

  Future<void> deleteAsset(String id) async {
    await _service.deleteAsset(id);
    ref.invalidateSelf();
  }
}

final assetNotifierProvider =
    AsyncNotifierProvider.autoDispose<AssetNotifier, List<AssetGroup>>(
  AssetNotifier.new,
);

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/asset_item.dart';
import '../../models/asset_group.dart';
import '../../models/enums.dart';
import '../../utils/date_format.dart';
import '../providers.dart';
import 'home_notifier.dart';

class AssetNotifier extends AutoDisposeFamilyAsyncNotifier<List<AssetGroup>, String> {
  @override
  Future<List<AssetGroup>> build(String month) async {
    final service = ref.watch(assetServiceProvider);
    final prevMonth = _previousMonthKey(month);

    final results = await Future.wait([
      service.getAssets(month: month),
      service.getAssets(month: prevMonth).catchError(
            (_) => <Map<String, dynamic>>[],
          ),
    ]);
    final rawAssets = results[0];
    final rawPrevAssets = results[1];

    final prevValueById = <String, num>{
      for (final raw in rawPrevAssets)
        if ((raw['valueHistory'] as List<dynamic>? ?? []).isNotEmpty)
          raw['id'] as String:
              ((raw['valueHistory'] as List<dynamic>).first['value'] as num),
    };

    return _groupAssets(rawAssets, prevValueById);
  }

  String _previousMonthKey(String month) {
    final parts = month.split('-');
    final year = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    return toMonthKey(DateTime(year, m - 1));
  }

  List<AssetGroup> _groupAssets(
    List<Map<String, dynamic>> rawAssets,
    Map<String, num> prevValueById,
  ) {
    final Map<String, List<AssetItem>> grouped = {};

    for (final raw in rawAssets) {
      final categoryId = raw['categoryId'] as String;
      final history = raw['valueHistory'] as List<dynamic>? ?? [];
      final latestValue = history.isNotEmpty
          ? (history.first['value'] as num).toInt()
          : 0;
      final assetId = raw['id'] as String;

      final item = AssetItem(
        id: assetId,
        name: raw['name'] as String,
        currentValue: latestValue,
        previousValue: prevValueById[assetId] ?? 0,
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

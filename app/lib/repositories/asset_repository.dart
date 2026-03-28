import 'package:lucide_icons/lucide_icons.dart';
import '../models/models.dart';

class AssetRepository {
  List<AssetGroup> getAssetGroups() => [
        AssetGroup(
          id: 'real-estate',
          name: '부동산',
          icon: LucideIcons.building2,
          colorKey: 'blue',
          items: [
            AssetItem(
              id: 're-1',
              name: '서울 아파트',
              currentValue: 1020000000,
              previousValue: 1000000000,
              lastUpdated: '2026-03-15',
              editedBy: '나',
            ),
            AssetItem(
              id: 're-2',
              name: '상가 건물',
              currentValue: 540000000,
              previousValue: 540000000,
              lastUpdated: '2026-03-10',
              editedBy: '김영수',
            ),
          ],
        ),
        AssetGroup(
          id: 'stocks',
          name: '주식/투자',
          icon: LucideIcons.trendingUp,
          colorKey: 'green',
          items: [
            AssetItem(
              id: 'st-1',
              name: 'S&P 500 ETF',
              currentValue: 216000000,
              previousValue: 210000000,
              lastUpdated: '2026-03-20',
              editedBy: '박지현',
            ),
            AssetItem(
              id: 'st-2',
              name: '테크 주식',
              currentValue: 114000000,
              previousValue: 118000000,
              lastUpdated: '2026-03-18',
              editedBy: '나',
            ),
          ],
        ),
        AssetGroup(
          id: 'cash',
          name: '현금/예금',
          icon: LucideIcons.wallet,
          colorKey: 'purple',
          items: [
            AssetItem(
              id: 'ca-1',
              name: '주거래 은행',
              currentValue: 54000000,
              previousValue: 50400000,
              lastUpdated: '2026-03-22',
              editedBy: '나',
            ),
            AssetItem(
              id: 'ca-2',
              name: '예금',
              currentValue: 144000000,
              previousValue: 143000000,
              lastUpdated: '2026-03-01',
              editedBy: '김영수',
            ),
          ],
        ),
        AssetGroup(
          id: 'loans',
          name: '대출/부채',
          icon: LucideIcons.creditCard,
          colorKey: 'red',
          items: [
            AssetItem(
              id: 'lo-1',
              name: '주택담보대출',
              currentValue: -360000000,
              previousValue: -366000000,
              lastUpdated: '2026-03-05',
              editedBy: '나',
            ),
            AssetItem(
              id: 'lo-2',
              name: '자동차 할부',
              currentValue: -30000000,
              previousValue: -32400000,
              lastUpdated: '2026-03-05',
              editedBy: '박지현',
            ),
          ],
        ),
      ];
}

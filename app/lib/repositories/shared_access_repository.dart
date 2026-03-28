import 'package:lucide_icons/lucide_icons.dart';
import '../models/models.dart';

class SharedAccessRepository {
  List<AssetSubCategory> getAssetSubCategories() => const [
        AssetSubCategory(id: 'real-estate', name: '부동산', icon: LucideIcons.home, color: 'blue'),
        AssetSubCategory(id: 'stocks', name: '주식/투자', icon: LucideIcons.trendingUp, color: 'green'),
        AssetSubCategory(id: 'cash', name: '현금/예금', icon: LucideIcons.wallet, color: 'purple'),
        AssetSubCategory(id: 'loans', name: '대출/부채', icon: LucideIcons.creditCard, color: 'red'),
      ];

  List<SharedUser> getSharedUsers() => [
        SharedUser(
          id: '1',
          name: '김지은',
          email: 'jieun@example.com',
          avatar: '👩',
          cashflowPermission: PermissionLevel.edit,
          assetPermissions: {
            'real-estate': PermissionLevel.edit,
            'stocks': PermissionLevel.edit,
            'cash': PermissionLevel.edit,
            'loans': PermissionLevel.view,
          },
        ),
        SharedUser(
          id: '2',
          name: '박민수',
          email: 'minsu@example.com',
          avatar: '👨',
          cashflowPermission: PermissionLevel.view,
          assetPermissions: {
            'real-estate': PermissionLevel.none,
            'stocks': PermissionLevel.view,
            'cash': PermissionLevel.view,
            'loans': PermissionLevel.none,
          },
        ),
      ];

  List<Invitation> getSentInvitations() => [
        Invitation(
          id: 'sent-1',
          email: 'sister@example.com',
          name: '홍지수',
          status: InvitationStatus.pending,
          cashflowPermission: PermissionLevel.view,
          assetPermissions: {
            'real-estate': PermissionLevel.view,
            'stocks': PermissionLevel.none,
            'cash': PermissionLevel.view,
            'loans': PermissionLevel.none,
          },
          message: '같이 자산 관리해요!',
          sentDate: '2026-03-24',
          expiryDate: '2026-03-31',
          isIncoming: false,
        ),
        Invitation(
          id: 'sent-2',
          email: 'friend@example.com',
          status: InvitationStatus.expired,
          cashflowPermission: PermissionLevel.view,
          assetPermissions: {
            'real-estate': PermissionLevel.none,
            'stocks': PermissionLevel.view,
            'cash': PermissionLevel.none,
            'loans': PermissionLevel.none,
          },
          sentDate: '2026-03-10',
          expiryDate: '2026-03-17',
          isIncoming: false,
        ),
      ];

  List<Invitation> getReceivedInvitations() => [
        Invitation(
          id: 'recv-1',
          email: 'dad@example.com',
          name: '홍아버지',
          avatar: '👨‍🦳',
          status: InvitationStatus.pending,
          cashflowPermission: PermissionLevel.edit,
          assetPermissions: {
            'real-estate': PermissionLevel.edit,
            'stocks': PermissionLevel.edit,
            'cash': PermissionLevel.view,
            'loans': PermissionLevel.none,
          },
          message: '가족 자산을 함께 관리합시다.',
          sentDate: '2026-03-25',
          expiryDate: '2026-04-01',
          isIncoming: true,
          inviterName: '홍아버지',
        ),
      ];
}

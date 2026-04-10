import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../design_system/tokens/colors.dart';
import '../design_system/tokens/typography.dart';
import '../design_system/tokens/spacing.dart';
import '../design_system/tokens/radius.dart';
import '../design_system/components/al_card.dart';
import '../design_system/components/al_button.dart';
import '../design_system/components/al_avatar.dart';
import '../design_system/components/al_bottom_sheet.dart';
import '../design_system/components/al_input.dart';
import '../design_system/components/al_month_selector.dart';
import '../design_system/components/al_screen_header.dart';
import '../models/models.dart';
import '../core/providers.dart';
import '../utils/format_korean_won.dart';
import '../utils/snackbar_helper.dart';

class ShareGroupDetailScreen extends ConsumerStatefulWidget {
  final String groupId;
  const ShareGroupDetailScreen({super.key, required this.groupId});

  @override
  ConsumerState<ShareGroupDetailScreen> createState() => _ShareGroupDetailScreenState();
}

class _ShareGroupDetailScreenState extends ConsumerState<ShareGroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedMonth = DateTime.now();

  Map<String, dynamic>? _group;
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _assets = [];
  bool _isLoading = true;

  String get _monthKey =>
      '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final service = ref.read(shareGroupServiceProvider);
      final results = await Future.wait([
        service.getGroup(widget.groupId),
        service.getGroupTransactions(widget.groupId, month: _monthKey),
        service.getGroupAssets(widget.groupId, month: _monthKey),
      ]);
      if (mounted) {
        setState(() {
          _group = results[0] as Map<String, dynamic>;
          _transactions = (results[1] as List).cast<Map<String, dynamic>>();
          _assets = (results[2] as List).cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goToPreviousMonth() {
    setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1));
    _loadData();
  }

  void _goToNextMonth() {
    setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1));
    _loadData();
  }

  void _showInviteSheet() {
    final emailController = TextEditingController();
    AlBottomSheet.show(
      context: context,
      title: '멤버 초대',
      child: Column(
        children: [
          AlInput(label: '이메일', placeholder: 'example@email.com', controller: emailController, keyboardType: TextInputType.emailAddress),
          SizedBox(height: AppSpacing.xl),
          AlButton(
            label: '초대하기',
            icon: Icon(LucideIcons.send, size: 16, color: Colors.white),
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty) { showErrorSnackBar(context, '이메일을 입력해 주세요'); return; }
              Navigator.of(context).pop();
              try {
                await ref.read(shareGroupServiceProvider).inviteToGroup(widget.groupId, toEmail: email);
                if (mounted) showSuccessSnackBar(context, '초대를 보냈습니다');
              } catch (e) {
                if (mounted) showErrorSnackBar(context, '$e');
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupName = _group?['name'] as String? ?? '그룹';
    final members = (_group?['members'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AlScreenHeader(
            title: groupName,
            showBack: true,
            action: IconButton(
              icon: Icon(LucideIcons.userPlus, size: 20, color: AppColors.emerald600),
              onPressed: _showInviteSheet,
            ),
          ),
          AlMonthSelector(selectedMonth: _selectedMonth, onPrevious: _goToPreviousMonth, onNext: _goToNextMonth),
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.emerald600,
              unselectedLabelColor: AppColors.gray500,
              indicatorColor: AppColors.emerald600,
              indicatorWeight: 2,
              labelStyle: AppTypography.label,
              tabs: [
                Tab(text: '멤버'),
                Tab(text: '거래'),
                Tab(text: '자산'),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMembersTab(members),
                      _buildTransactionsTab(),
                      _buildAssetsTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ─── 멤버 탭 ──────────────────────────────────

  Widget _buildMembersTab(List<Map<String, dynamic>> members) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        children: members.map((member) {
          final user = member['user'] as Map<String, dynamic>? ?? {};
          final name = user['name'] as String? ?? '';
          final email = user['email'] as String? ?? '';
          final role = member['role'] as String? ?? 'viewer';
          final roleLabel = GroupRole.fromString(role).label;

          return Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: AlCard(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: Row(
                children: [
                  AlAvatar.medium(
                    text: name.isNotEmpty ? name.characters.first : '?',
                    imageUrl: user['avatar'] as String?,
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: AppTypography.label),
                        SizedBox(height: 2),
                        Text(email, style: AppTypography.caption),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: role == 'admin' ? AppColors.emerald50 : AppColors.gray100,
                      borderRadius: AppRadius.fullAll,
                    ),
                    child: Text(roleLabel, style: AppTypography.caption.copyWith(
                      color: role == 'admin' ? AppColors.emerald700 : AppColors.gray600,
                      fontSize: 10, fontWeight: FontWeight.w600,
                    )),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── 거래 탭 ──────────────────────────────────

  Widget _buildTransactionsTab() {
    if (_transactions.isEmpty) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.inbox, size: 48, color: AppColors.gray300),
          SizedBox(height: AppSpacing.md),
          Text('공유된 거래가 없습니다', style: AppTypography.bodyMedium.copyWith(color: AppColors.gray500)),
        ],
      ));
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        children: _transactions.map((raw) {
          final type = raw['type'] as String? ?? 'expense';
          final isIncome = type == 'income';
          final name = raw['name'] as String? ?? '';
          final amount = (raw['amount'] as num?)?.toInt() ?? 0;
          final date = (raw['date'] as String? ?? '');
          final owner = raw['user'] as Map<String, dynamic>? ?? {};
          final ownerName = owner['name'] as String? ?? '';

          return Container(
            margin: EdgeInsets.only(bottom: AppSpacing.sm),
            child: AlCard(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: Row(
                children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: AppTypography.bodyMedium),
                      SizedBox(height: AppSpacing.xs),
                      Text('${raw['category'] ?? ''} · $ownerName', style: AppTypography.caption),
                      SizedBox(height: AppSpacing.xs),
                      Text(date.length >= 10 ? date.substring(0, 10) : date, style: AppTypography.caption.copyWith(color: AppColors.gray400)),
                    ],
                  )),
                  Text(
                    '${isIncome ? '+' : '-'}${formatKoreanWon(amount)}',
                    style: AppTypography.amountSmall.copyWith(color: isIncome ? AppColors.emerald600 : AppColors.red600),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── 자산 탭 ──────────────────────────────────

  Widget _buildAssetsTab() {
    if (_assets.isEmpty) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.wallet, size: 48, color: AppColors.gray300),
          SizedBox(height: AppSpacing.md),
          Text('공유된 자산이 없습니다', style: AppTypography.bodyMedium.copyWith(color: AppColors.gray500)),
        ],
      ));
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        children: _assets.map((raw) {
          final name = raw['name'] as String? ?? '';
          final catId = raw['categoryId'] as String? ?? '';
          final history = raw['valueHistory'] as List<dynamic>? ?? [];
          final value = history.isNotEmpty ? (history.first['value'] as num).toInt() : 0;
          final owner = raw['user'] as Map<String, dynamic>? ?? {};
          final ownerName = owner['name'] as String? ?? '';

          final catConfig = {
            'real-estate': (label: '부동산', icon: LucideIcons.home, color: AppColors.blue600),
            'stocks': (label: '주식', icon: LucideIcons.trendingUp, color: AppColors.green600),
            'cash': (label: '현금', icon: LucideIcons.banknote, color: AppColors.purple600),
            'loans': (label: '부채', icon: LucideIcons.creditCard, color: AppColors.red600),
          };
          final config = catConfig[catId];

          return Container(
            margin: EdgeInsets.only(bottom: AppSpacing.sm),
            child: AlCard(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: Row(
                children: [
                  Icon(config?.icon ?? LucideIcons.folder, size: 20, color: config?.color ?? AppColors.gray500),
                  SizedBox(width: AppSpacing.md),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: AppTypography.bodyMedium),
                      SizedBox(height: 2),
                      Text('${config?.label ?? catId} · $ownerName', style: AppTypography.caption),
                    ],
                  )),
                  Text(formatKoreanWon(value), style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../design_system/tokens/colors.dart';

class BottomNav extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const BottomNav({super.key, required this.navigationShell});

  static final _items = [
    (icon: LucideIcons.home, label: '홈'),
    (icon: LucideIcons.trendingUp, label: '수입/지출'),
    (icon: LucideIcons.wallet, label: '자산'),
    (icon: LucideIcons.barChart3, label: '리포트'),
    (icon: LucideIcons.menu, label: '더보기'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.gray200)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              children: List.generate(_items.length, (index) {
                final item = _items[index];
                final isActive = navigationShell.currentIndex == index;
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => navigationShell.goBranch(
                      index,
                      initialLocation: true,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item.icon,
                          size: 20,
                          color: isActive
                              ? AppColors.emerald600
                              : AppColors.gray400,
                        ),
                        SizedBox(height: 4),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight:
                                isActive ? FontWeight.w500 : FontWeight.normal,
                            color: isActive
                                ? AppColors.emerald600
                                : AppColors.gray500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

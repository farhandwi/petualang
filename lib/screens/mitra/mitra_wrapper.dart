import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/mitra_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import 'mitra_dashboard_screen.dart';
import 'mitra_item_list_screen.dart';
import 'mitra_order_list_screen.dart';
import 'mitra_shop_profile_screen.dart';

class _MitraDestination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const _MitraDestination(this.icon, this.selectedIcon, this.label);
}

const List<_MitraDestination> _kMitraDestinations = [
  _MitraDestination(Icons.dashboard_outlined, Icons.dashboard_rounded, 'Dashboard'),
  _MitraDestination(Icons.inventory_2_outlined, Icons.inventory_2_rounded, 'Alat'),
  _MitraDestination(Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Pesanan'),
  _MitraDestination(Icons.storefront_outlined, Icons.storefront_rounded, 'Toko'),
];

class MitraWrapper extends StatefulWidget {
  const MitraWrapper({super.key});

  @override
  State<MitraWrapper> createState() => _MitraWrapperState();
}

class _MitraWrapperState extends State<MitraWrapper> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    MitraDashboardScreen(),
    MitraItemListScreen(),
    MitraOrderListScreen(),
    MitraShopProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final mitra = context.read<MitraProvider>();
      mitra.setToken(auth.token);
      mitra.refreshPendingOrderCount();
    });
  }

  void _switchTab(int index) {
    if (_currentIndex != index) setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final body = IndexedStack(index: _currentIndex, children: _pages);
    // Tab Pesanan ada di index 2.
    final pendingOrders = context.watch<MitraProvider>().pendingOrderCount;
    final badges = <int, int>{if (pendingOrders > 0) 2: pendingOrders};

    if (context.isMobile) {
      return Scaffold(
        backgroundColor: colors.background,
        body: body,
        bottomNavigationBar: _MobileBottomNav(
          currentIndex: _currentIndex,
          onTap: _switchTab,
          badges: badges,
        ),
      );
    }

    final extended = context.isDesktop;
    return Scaffold(
      backgroundColor: colors.background,
      body: Row(
        children: [
          _SideRail(
            currentIndex: _currentIndex,
            onTap: _switchTab,
            extended: extended,
            badges: badges,
          ),
          VerticalDivider(width: 1, thickness: 1, color: colors.border),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _MobileBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Map<int, int> badges;
  const _MobileBottomNav({
    required this.currentIndex,
    required this.onTap,
    this.badges = const {},
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < _kMitraDestinations.length; i++)
                Expanded(
                  child: _NavBarItem(
                    icon: _kMitraDestinations[i].selectedIcon,
                    label: _kMitraDestinations[i].label,
                    isSelected: currentIndex == i,
                    badge: badges[i],
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SideRail extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool extended;
  final Map<int, int> badges;
  const _SideRail({
    required this.currentIndex,
    required this.onTap,
    required this.extended,
    this.badges = const {},
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final brandWidth = extended ? 220.0 : 76.0;
    return SafeArea(
      right: false,
      child: NavigationRail(
        backgroundColor: colors.surface,
        selectedIndex: currentIndex,
        onDestinationSelected: onTap,
        extended: extended,
        minWidth: 76,
        minExtendedWidth: 220,
        labelType: extended
            ? NavigationRailLabelType.none
            : NavigationRailLabelType.all,
        useIndicator: true,
        indicatorColor: colors.primaryOrange.withValues(alpha: 0.12),
        selectedIconTheme: IconThemeData(color: colors.primaryOrange, size: 26),
        unselectedIconTheme: IconThemeData(color: colors.textMuted, size: 24),
        selectedLabelTextStyle: GoogleFonts.beVietnamPro(
          color: colors.primaryOrange,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        unselectedLabelTextStyle: GoogleFonts.beVietnamPro(
          color: colors.textSecondary,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        leading: SizedBox(
          width: brandWidth,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: extended ? 20 : 12,
              vertical: 20,
            ),
            child: extended
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _MitraBrand(),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          'Mitra Toko',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.beVietnamPro(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ],
                  )
                : const Center(child: _MitraBrand()),
          ),
        ),
        destinations: [
          for (var i = 0; i < _kMitraDestinations.length; i++)
            NavigationRailDestination(
              icon: _BadgedIcon(
                icon: _kMitraDestinations[i].icon,
                color: colors.textMuted,
                badge: badges[i],
                size: 24,
              ),
              selectedIcon: _BadgedIcon(
                icon: _kMitraDestinations[i].selectedIcon,
                color: colors.primaryOrange,
                badge: badges[i],
                size: 26,
              ),
              label: Text(_kMitraDestinations[i].label),
              padding: const EdgeInsets.symmetric(vertical: 4),
            ),
        ],
      ),
    );
  }
}

class _MitraBrand extends StatelessWidget {
  const _MitraBrand();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppTheme.primaryOrange,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 22),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int? badge;
  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? context.colors.primaryOrange : context.colors.textMuted;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _BadgedIcon(icon: icon, color: color, badge: badge, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.beVietnamPro(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Icon dengan badge merah kecil di pojok kanan atas saat [badge] > 0.
class _BadgedIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int? badge;
  final double size;
  const _BadgedIcon({
    required this.icon,
    required this.color,
    this.badge,
    this.size = 22,
  });

  @override
  Widget build(BuildContext context) {
    final n = badge ?? 0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, color: color, size: size),
        if (n > 0)
          Positioned(
            right: -6,
            top: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.colors.surface, width: 1.5),
              ),
              child: Center(
                child: Text(
                  n > 99 ? '99+' : '$n',
                  style: GoogleFonts.beVietnamPro(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

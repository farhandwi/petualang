import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'explore/explore_screen.dart';
import 'dm/dm_list_screen.dart';
import 'order_screen.dart';

class _NavDestination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const _NavDestination(this.icon, this.selectedIcon, this.label);
}

const List<_NavDestination> _kDestinations = [
  _NavDestination(Icons.home_outlined, Icons.home_rounded, 'Beranda'),
  _NavDestination(Icons.search_outlined, Icons.search_rounded, 'Jelajah'),
  _NavDestination(
      Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, 'Chat'),
  _NavDestination(Icons.receipt_long_outlined, Icons.receipt_long_rounded,
      'Pesanan'),
  _NavDestination(Icons.person_outline_rounded, Icons.person_rounded, 'Profil'),
];

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => MainWrapperState();
}

class MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;
  bool _hasShownCompletenessNotif = false;

  void switchTab(int index) {
    if (_currentIndex != index) {
      setState(() => _currentIndex = index);
    }
  }

  final List<Widget> _pages = [
    const HomeScreen(),
    const ExploreScreen(),
    const DmListScreen(),
    const OrderScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkProfileCompleteness();
    });
  }

  void _checkProfileCompleteness() {
    if (_hasShownCompletenessNotif) return;

    final auth = context.read<AuthProvider>();
    final user = auth.user;

    if (user != null && user.profileCompleteness < 1.0) {
      _hasShownCompletenessNotif = true;
      final percentage = (user.profileCompleteness * 100).toInt();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Data diri Anda belum lengkap ($percentage%). Lengkapi sekarang untuk pengalaman lebih baik.',
            style: GoogleFonts.beVietnamPro(fontSize: 13),
          ),
          backgroundColor: AppTheme.primaryOrange,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Lengkapi',
            textColor: Colors.white,
            onPressed: () {
              setState(() => _currentIndex = 4);
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final body = IndexedStack(index: _currentIndex, children: _pages);

    if (context.isMobile) {
      return Scaffold(
        backgroundColor: colors.background,
        body: body,
        bottomNavigationBar: _MobileBottomNav(
          currentIndex: _currentIndex,
          onTap: switchTab,
        ),
      );
    }

    final extended = context.isDesktop;
    return Scaffold(
      backgroundColor: colors.background,
      body: Row(
        children: [
          _SideNavigationRail(
            currentIndex: _currentIndex,
            onTap: switchTab,
            extended: extended,
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
  const _MobileBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < _kDestinations.length; i++)
                _NavBarItem(
                  icon: _kDestinations[i].selectedIcon,
                  label: _kDestinations[i].label,
                  isSelected: currentIndex == i,
                  onTap: () => onTap(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SideNavigationRail extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool extended;

  const _SideNavigationRail({
    required this.currentIndex,
    required this.onTap,
    required this.extended,
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
        indicatorColor: colors.primaryOrange.withOpacity(0.12),
        selectedIconTheme:
            IconThemeData(color: colors.primaryOrange, size: 26),
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
                      _BrandMark(),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          'Petualang',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.beVietnamPro(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  )
                : Center(child: _BrandMark()),
          ),
        ),
        destinations: [
          for (final d in _kDestinations)
            NavigationRailDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: Text(d.label),
              padding: const EdgeInsets.symmetric(vertical: 4),
            ),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppTheme.primaryOrange,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.landscape_rounded,
          color: Colors.white, size: 22),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isSelected ? context.colors.primaryOrange : context.colors.textMuted;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
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

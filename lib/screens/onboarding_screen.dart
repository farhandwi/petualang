import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;

  final List<Map<String, String>> _pages = [
    {
      'image': 'assets/images/onboarding_illustration.png',
      'badge': 'MULAI PETUALANGAN',
      'title': 'Cari Partner\nMendaki',
      'subtitle':
          'Temukan teman petualangan yang memiliki hobi dan visi yang sama untuk menaklukkan puncak impian Anda.',
    },
    {
      'image': 'assets/images/onboarding_sewa_tiket.png',
      'badge': 'PERSIAPAN MUDAH',
      'title': 'Sewa Alat &\nPesan Tiket',
      'subtitle':
          'Kemudahan menyewa perlengkapan outdoor dan memesan tiket wisata alam dalam satu aplikasi.',
    },
    {
      'image': 'assets/images/onboarding_komunitas.png',
      'badge': 'JARINGAN LUAS',
      'title': 'Gabung\nKomunitas',
      'subtitle':
          'Perluas jaringanmu dengan bergabung di komunitas pecinta alam di seluruh Indonesia.',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNextPressed() {
    if (_currentPageIndex < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.read<AuthProvider>().completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = context.isWide;
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPageIndex = i),
                itemBuilder: (context, index) => _OnboardingPage(
                  data: _pages[index],
                  isWide: isWide,
                ),
              ),
            ),
            _BottomBar(
              currentIndex: _currentPageIndex,
              total: _pages.length,
              onNext: _onNextPressed,
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final Map<String, String> data;
  final bool isWide;
  const _OnboardingPage({required this.data, required this.isWide});

  @override
  Widget build(BuildContext context) {
    final image = ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Image.asset(data['image']!, fit: BoxFit.cover),
    );

    final imageBox = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: image,
    );

    final textCol = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: context.colors.primaryOrange.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            data['badge']!,
            style: GoogleFonts.beVietnamPro(
              color: context.colors.primaryOrange,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          data['title']!,
          style: GoogleFonts.beVietnamPro(
            color: context.colors.textPrimary,
            fontSize: context.responsive<double>(
                mobile: 34, tablet: 40, desktop: 46),
            fontWeight: FontWeight.w800,
            height: 1.15,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          data['subtitle']!,
          style: GoogleFonts.beVietnamPro(
            color: context.colors.textSecondary,
            fontSize: context.responsive<double>(
                mobile: 15, tablet: 16, desktop: 17),
            height: 1.6,
          ),
        ),
      ],
    );

    if (isWide) {
      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.responsive<double>(
              mobile: 24, tablet: 48, desktop: 72),
          vertical: 32,
        ),
        child: ContentConstrained(
          maxWidth: 1180,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: 6, child: AspectRatio(
                aspectRatio: 4 / 3, child: imageBox)),
              const SizedBox(width: 56),
              Expanded(flex: 5, child: textCol),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 11, child: imageBox),
          const SizedBox(height: 48),
          Expanded(flex: 8, child: textCol),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int currentIndex;
  final int total;
  final VoidCallback onNext;
  const _BottomBar({
    required this.currentIndex,
    required this.total,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        context.responsive<double>(mobile: 32, tablet: 48, desktop: 72),
        20,
        context.responsive<double>(mobile: 32, tablet: 48, desktop: 72),
        32,
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: context.colors.border, width: 1)),
      ),
      child: ContentConstrained(
        maxWidth: 1180,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: List.generate(
                total,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(right: 6),
                  height: 6,
                  width: currentIndex == index ? 24 : 6,
                  decoration: BoxDecoration(
                    color: currentIndex == index
                        ? context.colors.primaryOrange
                        : context.colors.textSecondary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.primaryOrange,
                minimumSize: const Size(100, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                elevation: 0,
              ),
              child: Text(
                currentIndex == total - 1 ? 'Mulai' : 'Lanjut',
                style: GoogleFonts.beVietnamPro(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

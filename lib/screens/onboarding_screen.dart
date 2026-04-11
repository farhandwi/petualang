import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

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
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Full PageView for Content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPageIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Image part
                        Expanded(
                          flex: 11,
                          child: Container(
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
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Image.asset(
                                _pages[index]['image']!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        // Spacer
                        const SizedBox(height: 48),
                        // Text Part
                        Expanded(
                          flex: 8,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: context.colors.primaryOrange.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _pages[index]['badge']!,
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
                                _pages[index]['title']!,
                                style: GoogleFonts.beVietnamPro(
                                  color: context.colors.textPrimary,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                  height: 1.15,
                                  letterSpacing: -1,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _pages[index]['subtitle']!,
                                style: GoogleFonts.beVietnamPro(
                                  color: context.colors.textSecondary,
                                  fontSize: 15,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Bottom Action Bar (Fixed at bottom)
            Container(
              padding: const EdgeInsets.fromLTRB(32, 20, 32, 32),
              decoration: BoxDecoration(
                color: context.colors.surface,
                border: Border(top: BorderSide(color: context.colors.border, width: 1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page Indicators
                  Row(
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 6),
                        height: 6,
                        width: _currentPageIndex == index ? 24 : 6,
                        decoration: BoxDecoration(
                          color: _currentPageIndex == index
                              ? context.colors.primaryOrange
                              : context.colors.textSecondary.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  // Button CTA
                  ElevatedButton(
                    onPressed: _onNextPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.primaryOrange,
                      minimumSize: const Size(100, 54), // Overrides global double.infinity
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      elevation: 0,
                    ),
                    child: Text(
                      _currentPageIndex == _pages.length - 1 ? 'Mulai' : 'Lanjut',
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
          ],
        ),
      ),
    );
  }
}

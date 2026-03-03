import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../utils/colors.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Data per slide dengan warna unik masing-masing
  final List<OnboardingData> _data = [
    OnboardingData(
      title: "Solusi Parkir Modern",
      description:
          "Kelola kendaraan masuk dan keluar dengan sistem yang cerdas, cepat, dan efisien.",
      icon: Icons.local_parking_rounded,
      gradientColors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
      bgAccent: Color(0xFFEDE9FE),
    ),
    OnboardingData(
      title: "Keamanan Terjamin",
      description:
          "Pantau setiap transaksi secara real-time dengan sistem keamanan berlapis untuk ketenangan pikiran Anda.",
      icon: Icons.shield_rounded,
      gradientColors: [Color(0xFF0EA5E9), Color(0xFF6366F1)],
      bgAccent: Color(0xFFE0F2FE),
    ),
    OnboardingData(
      title: "Laporan Terintegrasi",
      description:
          "Analisis pendapatan harian dan bulanan langsung dari genggaman tangan Anda kapan saja.",
      icon: Icons.bar_chart_rounded,
      gradientColors: [Color(0xFF10B981), Color(0xFF0EA5E9)],
      bgAccent: Color(0xFFD1FAE5),
    ),
  ];

  void _goToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final data = _data[_currentPage];

    return Scaffold(
      body: AnimatedContainer(
        duration: 500.ms,
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              data.gradientColors[0].withOpacity(0.08),
              data.gradientColors[1].withOpacity(0.04),
              Colors.white,
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // ── Decorative blobs ──
            Positioned(
              top: -80,
              right: -80,
              child: _Blob(size: 260, color: data.gradientColors[0].withOpacity(0.12)),
            ),
            Positioned(
              top: 120,
              left: -60,
              child: _Blob(size: 160, color: data.gradientColors[1].withOpacity(0.10)),
            ),
            Positioned(
              bottom: 180,
              right: -40,
              child: _Blob(size: 140, color: data.gradientColors[0].withOpacity(0.08)),
            ),
            Positioned(
              bottom: -60,
              left: -60,
              child: _Blob(size: 200, color: data.gradientColors[1].withOpacity(0.10)),
            ),

            // ── Content ──
            SafeArea(
              child: Column(
                children: [
                  // Top bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Row(
                      children: [
                        // Mini logo badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: data.gradientColors,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.local_parking_rounded, color: Colors.white, size: 16),
                              SizedBox(width: 4),
                              Text(
                                "UKK PARKIR",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Skip
                        TextButton(
                          onPressed: _goToLogin,
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.7),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          child: Text(
                            "Lewati",
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fade(duration: 400.ms),

                  // Page content
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (i) => setState(() => _currentPage = i),
                      itemCount: _data.length,
                      itemBuilder: (context, index) {
                        final d = _data[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // ── Hero illustration ──
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Outer soft ring
                                  Container(
                                    width: 220,
                                    height: 220,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: d.bgAccent,
                                    ),
                                  )
                                      .animate(key: ValueKey('ring_$index'))
                                      .scale(
                                        begin: const Offset(0.7, 0.7),
                                        duration: 700.ms,
                                        curve: Curves.easeOutBack,
                                      ),
                                  // Middle gradient circle
                                  Container(
                                    width: 170,
                                    height: 170,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: d.gradientColors,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: d.gradientColors[0].withOpacity(0.4),
                                          blurRadius: 30,
                                          offset: const Offset(0, 15),
                                        ),
                                      ],
                                    ),
                                  )
                                      .animate(key: ValueKey('circle_$index'))
                                      .scale(
                                        begin: const Offset(0.6, 0.6),
                                        delay: 150.ms,
                                        duration: 700.ms,
                                        curve: Curves.easeOutBack,
                                      ),
                                  // Icon
                                  Icon(
                                    d.icon,
                                    size: 80,
                                    color: Colors.white,
                                  )
                                      .animate(key: ValueKey('icon_$index'))
                                      .scale(
                                        begin: const Offset(0.5, 0.5),
                                        delay: 300.ms,
                                        duration: 600.ms,
                                        curve: Curves.easeOutBack,
                                      )
                                      .fade(delay: 200.ms),
                                  // Sparkle dots
                                  ...List.generate(4, (i) {
                                    final angles = [
                                      const Offset(-90, -90),
                                      const Offset(90, -80),
                                      const Offset(-80, 90),
                                      const Offset(85, 85),
                                    ];
                                    return Positioned(
                                      left: 110 + angles[i].dx,
                                      top: 110 + angles[i].dy,
                                      child: Container(
                                        width: i.isEven ? 10 : 8,
                                        height: i.isEven ? 10 : 8,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.9),
                                          shape: BoxShape.circle,
                                        ),
                                      )
                                          .animate(key: ValueKey('dot_${index}_$i'))
                                          .scale(
                                            delay: Duration(milliseconds: 400 + i * 80),
                                            duration: 500.ms,
                                            curve: Curves.easeOutBack,
                                          ),
                                    );
                                  }),
                                ],
                              ),

                              const SizedBox(height: 56),

                              // Tag chip
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: d.bgAccent,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "Fitur ${index + 1} dari ${_data.length}",
                                  style: TextStyle(
                                    color: d.gradientColors[0],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              )
                                  .animate(key: ValueKey('chip_$index'))
                                  .fade(duration: 400.ms)
                                  .slideY(begin: 0.3),

                              const SizedBox(height: 16),

                              // Title
                              Text(
                                d.title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                  fontSize: 28,
                                  letterSpacing: -0.8,
                                  height: 1.15,
                                ),
                              )
                                  .animate(key: ValueKey('title_$index'))
                                  .fade(delay: 50.ms, duration: 400.ms)
                                  .slideY(begin: 0.25),

                              const SizedBox(height: 16),

                              // Description
                              Text(
                                d.description,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 15,
                                  height: 1.6,
                                ),
                              )
                                  .animate(key: ValueKey('desc_$index'))
                                  .fade(delay: 120.ms, duration: 400.ms)
                                  .slideY(begin: 0.25),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // ── Bottom section ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
                    child: Column(
                      children: [
                        // Indicators
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _data.length,
                            (i) => AnimatedContainer(
                              duration: 350.ms,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: 8,
                              width: _currentPage == i ? 28 : 8,
                              decoration: BoxDecoration(
                                gradient: _currentPage == i
                                    ? LinearGradient(colors: data.gradientColors)
                                    : null,
                                color: _currentPage == i
                                    ? null
                                    : AppColors.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // CTA button
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            gradient: LinearGradient(colors: data.gradientColors),
                            boxShadow: [
                              BoxShadow(
                                color: data.gradientColors[0].withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(22),
                              onTap: () {
                                if (_currentPage < _data.length - 1) {
                                  _pageController.nextPage(
                                    duration: 500.ms,
                                    curve: Curves.easeInOutCubic,
                                  );
                                } else {
                                  _goToLogin();
                                }
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _currentPage == _data.length - 1
                                          ? "Mulai Sekarang"
                                          : "Selanjutnya",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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

/// Simple blob/circle decoration widget
class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final IconData icon;
  final List<Color> gradientColors;
  final Color bgAccent;

  OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradientColors,
    required this.bgAccent,
  });
}

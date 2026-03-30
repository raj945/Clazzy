import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../providers/time_tracking_provider.dart';
import '../constants/colors.dart';
import 'home_screen.dart';
import 'calendar_screen.dart';
import 'goals_screen.dart';
import 'stats_screen.dart';
import 'knowledge_hub_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  // Global key for accessing navigation
  static final GlobalKey<AppShellState> shellKey = GlobalKey<AppShellState>();

  @override
  State<AppShell> createState() => AppShellState();
}

class AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  late PageController _pageController;

  final List<Widget> _screens = const [
    HomeScreen(),
    CalendarScreen(),
    GoalsScreen(),
    KnowledgeHubScreen(),
    StatsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
  }

  void _navigateToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // Public method for external navigation
  void navigateTo(int index) {
    _navigateToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TimeTrackerProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
          );
        }

        return Scaffold(
          extendBody: true, // Important for floating navbar
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              // Global Background Gradient
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1A1A1A), // Very Dark Grey
                      Color(0xFF000000), // Black
                      Color(0xFF121212), // Dark Grey
                    ],
                  ),
                ),
              ),

              // Main Content with swipe navigation
              PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                physics: const BouncingScrollPhysics(),
                children: _screens,
              ),

              // Floating Bottom Navigation
              Positioned(
                bottom: 24,
                left: 20,
                right: 20,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildNavItem(
                            Icons.home_outlined,
                            Icons.home,
                            'Home',
                            0,
                          ),
                          _buildNavItem(
                            Icons.calendar_month_outlined,
                            Icons.calendar_month,
                            'Calendar',
                            1,
                          ),
                          _buildNavItem(
                            Icons.flag_outlined,
                            Icons.flag,
                            'Goals',
                            2,
                          ),
                          _buildNavItem(
                            Icons.library_books_outlined,
                            Icons.library_books,
                            'Library',
                            3,
                          ),
                          _buildNavItem(
                            Icons.bar_chart_outlined,
                            Icons.bar_chart,
                            'Stats',
                            4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavItem(
    IconData icon,
    IconData activeIcon,
    String label,
    int index,
  ) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _navigateToPage(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(isSelected ? 10 : 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isSelected ? activeIcon : icon,
          color: isSelected ? Colors.black : Colors.grey.shade400,
          size: 24,
        ),
      ),
    );
  }
}

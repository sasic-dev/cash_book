import 'dart:async';
import 'package:flutter/material.dart';
import '../view_models/cash_book_view_model.dart';
import 'home_screen.dart';

/// Clean, modern launch screen for Cash Book application with no raw loaders.
class SplashScreen extends StatefulWidget {
  final CashBookViewModel? injectedViewModel;
  final Duration duration;

  const SplashScreen({
    super.key,
    this.injectedViewModel,
    this.duration = const Duration(milliseconds: 1000),
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

/// Alias for SplashScreen representing the clean launch screen
typedef LaunchScreen = SplashScreen;

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final CashBookViewModel _viewModel;
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _slideAnimation;
  bool _hasNavigated = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.injectedViewModel ?? CashBookViewModel();

    // Start initialization if not yet completed
    if (widget.injectedViewModel == null) {
      _viewModel.init();
    }

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.1, 0.9, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.75, curve: Curves.easeOutBack),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.10),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();
    _scheduleNavigation();
  }

  void _scheduleNavigation() {
    _timer = Timer(widget.duration, _navigateToHome);
  }

  Future<void> _navigateToHome() async {
    if (!mounted || _hasNavigated) return;

    // Ensure viewModel data loading is complete before navigating
    if (_viewModel.isLoading) {
      while (_viewModel.isLoading && mounted) {
        await Future.delayed(const Duration(milliseconds: 30));
      }
    }

    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            HomeScreen(viewModel: _viewModel),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      body: GestureDetector(
        onTap: _navigateToHome, // Tap anywhere to skip smoothly
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0F172A),
                Color(0xFF090D16),
              ],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                // Centered Brand Artwork & Titles
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // App Icon with smooth rounded squircle and soft elevation
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                blurRadius: 24,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: Image.asset(
                              'assets/icons/app_icon.png',
                              width: 96,
                              height: 96,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                color: const Color(0xFF1E40AF),
                                child: const Icon(
                                  Icons.account_balance_wallet_rounded,
                                  size: 48,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Brand Title
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Column(
                            children: [
                              const Text(
                                'Cash Book',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFF334155),
                                  ),
                                ),
                                child: const Text(
                                  'SMART LEDGER',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom Trust & Privacy Badge (No loaders)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 24,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 14,
                            color: const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            '100% Private • Local Storage',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.2,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

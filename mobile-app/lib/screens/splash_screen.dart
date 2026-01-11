import 'dart:math' as math;
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;
  
  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _particleController;
  
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;
  late Animation<double> _textFadeAnim;
  late Animation<double> _subtitleFadeAnim;

  @override
  void initState() {
    super.initState();
    
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 0.4, curve: Curves.elasticOut)),
    );
    
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 0.3, curve: Curves.easeOut)),
    );
    
    _slideAnim = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.2, 0.5, curve: Curves.easeOutCubic)),
    );
    
    _textFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.3, 0.6, curve: Curves.easeOut)),
    );
    
    _subtitleFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.5, 0.8, curve: Curves.easeOut)),
    );

    _mainController.forward();
    
    Future.delayed(const Duration(milliseconds: 2500), () {
      widget.onComplete();
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Stack(
        children: [
          // 背景粒子
          ...List.generate(20, (index) => _buildParticle(index)),
          
          // 光晕背景
          Center(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 300 + (_pulseController.value * 50),
                  height: 300 + (_pulseController.value * 50),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF333333).withAlpha((30 + _pulseController.value * 20).toInt()),
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // 主内容
          Center(
            child: AnimatedBuilder(
              animation: _mainController,
              builder: (context, child) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Transform.scale(
                      scale: _scaleAnim.value,
                      child: Opacity(
                        opacity: _fadeAnim.value,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(100),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: Image.asset('assets/icon.png', fit: BoxFit.cover),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // 标题
                    Transform.translate(
                      offset: Offset(0, _slideAnim.value),
                      child: Opacity(
                        opacity: _textFadeAnim.value,
                        child: const Column(
                          children: [
                            Text(
                              'Study Monitor',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // 副标题
                    Opacity(
                      opacity: _subtitleFadeAnim.value,
                      child: const Text(
                        '专注学习，追踪进度',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF666666),
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 60),
                    
                    // 加载指示器
                    Opacity(
                      opacity: _subtitleFadeAnim.value,
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(
                            Colors.white.withAlpha(100),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          
          // 底部文字
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _subtitleFadeAnim,
              builder: (context, child) {
                return Opacity(
                  opacity: _subtitleFadeAnim.value * 0.5,
                  child: const Text(
                    'v1.0',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF444444),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticle(int index) {
    final random = math.Random(index);
    final startX = random.nextDouble() * 400 - 50;
    final startY = random.nextDouble() * 800;
    final size = random.nextDouble() * 3 + 1;
    final speed = random.nextDouble() * 0.5 + 0.3;
    final delay = random.nextDouble();
    
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        final progress = ((_particleController.value + delay) % 1.0);
        final y = startY - (progress * 200 * speed);
        final opacity = (1 - progress) * 0.3;
        
        return Positioned(
          left: startX + math.sin(progress * math.pi * 2) * 20,
          top: y,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withAlpha((opacity * 255).toInt()),
            ),
          ),
        );
      },
    );
  }
}

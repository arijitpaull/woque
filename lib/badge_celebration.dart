import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class BadgeCelebrationScreen extends StatefulWidget {
  final String badgeTitle;
  final String badgeDescription;
  final String avatarImage;
  final Duration displayDuration;
  final VoidCallback? onDismiss;

  const BadgeCelebrationScreen({
    Key? key,
    required this.badgeTitle,
    required this.badgeDescription,
    required this.avatarImage,
    this.displayDuration = const Duration(seconds: 3),
    this.onDismiss,
  }) : super(key: key);

  @override
  State<BadgeCelebrationScreen> createState() => _BadgeCelebrationScreenState();
}

class _BadgeCelebrationScreenState extends State<BadgeCelebrationScreen> 
    with TickerProviderStateMixin {
  
  late AnimationController _mainController;
  late AnimationController _particleController;
  late AnimationController _exitController;
  late AnimationController _pulseController;
  
  
  late Animation<double> _badgeScaleAnimation;
  late Animation<double> _badgeOpacityAnimation;
  
  
  late Animation<double> _titleSlideAnimation;
  late Animation<double> _titleOpacityAnimation;
  
  
  late Animation<double> _descOpacityAnimation;
  
  
  late Animation<double> _achievementScaleAnimation;
  late Animation<double> _achievementOpacityAnimation;
  
  
  late Animation<double> _backgroundOpacityAnimation;
  late Animation<double> _exitOpacityAnimation;
  late Animation<double> _exitScaleAnimation;
  
  
  late Timer _dismissTimer;
  bool _isExiting = false;
  
  
  final Color backgroundColor = const Color(0xFFF5F2EB);

  @override
  void initState() {
    super.initState();
    
    
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );
    
    
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    
    
    _backgroundOpacityAnimation = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );
    
    
    _achievementOpacityAnimation = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.1, 0.5, curve: Curves.easeOut),
    );
    
    _achievementScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.7, end: 1.05).chain(
          CurveTween(curve: Curves.easeOutCubic),
        ),
        weight: 80,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.05, end: 1.0).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 20,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.1, 0.5),
      ),
    );
    
    
    _badgeScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.4, end: 1.08).chain(
          CurveTween(curve: Curves.elasticOut),
        ),
        weight: 100,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.08, end: 1.0).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 20,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 0.7),
      ),
    );
    
    _badgeOpacityAnimation = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
    );
    
    
    _titleOpacityAnimation = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
    );
    
    _titleSlideAnimation = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic),
      ),
    );
    
    
    _descOpacityAnimation = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
    );
    
    
    _particleController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();
    
    
    _exitController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _exitOpacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeInCubic),
      ),
    );
    
    _exitScaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: Curves.easeInCubic,
      ),
    );
    
    
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        _mainController.forward();
      }
    });
    
    
    _dismissTimer = Timer(widget.displayDuration, _startExitAnimation);
  }

  void _startExitAnimation() {
    if (mounted) {
      setState(() {
        _isExiting = true;
      });
      
      
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
      
      _exitController.forward().whenComplete(() {
        Navigator.of(context).pop();
        if (widget.onDismiss != null) {
          widget.onDismiss!();
        }
      });
    }
  }

  @override
  void dispose() {
    
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    
    _mainController.dispose();
    _particleController.dispose();
    _exitController.dispose();
    _pulseController.dispose();
    _dismissTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    
    final colorScheme = Theme.of(context).colorScheme;
    final primary = colorScheme.primary;
    final secondary = colorScheme.secondary;
    final tertiary = colorScheme.tertiary;
    
    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!_isExiting) {
            _dismissTimer.cancel();
            _startExitAnimation();
          }
        },
        child: Stack(
          fit: StackFit.expand, 
          children: [
            
            AnimatedBuilder(
              animation: _isExiting ? _exitController : _mainController,
              builder: (context, child) {
                return Opacity(
                  opacity: _isExiting 
                      ? _exitOpacityAnimation.value 
                      : _backgroundOpacityAnimation.value,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.8,
                        colors: [
                          backgroundColor.withOpacity(0.98), 
                          backgroundColor.withOpacity(0.95),
                          backgroundColor.withOpacity(0.92),
                        ],
                        stops: const [0.2, 0.5, 1.0],
                      ),
                    ),
                  ),
                );
              },
            ),
            
            
            AnimatedBuilder(
              animation: _isExiting ? _exitController : _mainController,
              builder: (context, child) {
                final opacity = _isExiting 
                    ? _exitOpacityAnimation.value 
                    : _backgroundOpacityAnimation.value;
                
                return Opacity(
                  opacity: opacity,
                  child: SizedBox.expand(
                    child: Stack(
                      children: List.generate(50, (index) {
                        return EnhancedParticleWidget(
                          controller: _particleController,
                          pulseController: _pulseController,
                          index: index,
                          colors: [secondary, tertiary, primary],
                        );
                      }),
                    ),
                  ),
                );
              },
            ),
            
            
            AnimatedBuilder(
              animation: Listenable.merge([_mainController, _exitController]),
              builder: (context, child) {
                
                final exitScale = _isExiting ? _exitScaleAnimation.value : 1.0;
                final exitOpacity = _isExiting ? _exitOpacityAnimation.value : 1.0;
                
                return Opacity(
                  opacity: exitOpacity,
                  child: Transform.scale(
                    scale: exitScale,
                    child: child,
                  ),
                );
              },
              child: SafeArea(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      
                      AnimatedBuilder(
                        animation: _mainController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _achievementOpacityAnimation.value,
                            child: Transform.scale(
                              scale: _achievementScaleAnimation.value,
                              child: child,
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            color: tertiary.withOpacity(0.2),
                            border: Border.all(
                              color: tertiary.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'ACHIEVEMENT UNLOCKED',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: tertiary,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      
                      AnimatedBuilder(
                        animation: _mainController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _badgeOpacityAnimation.value,
                            child: Transform.scale(
                              scale: _badgeScaleAnimation.value,
                              child: child,
                            ),
                          );
                        },
                        child: _buildAnimatedBadge(context, tertiary, secondary),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      
                      AnimatedBuilder(
                        animation: _mainController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _titleOpacityAnimation.value,
                            child: Transform.translate(
                              offset: Offset(0, _titleSlideAnimation.value),
                              child: child,
                            ),
                          );
                        },
                        child: EnhancedShimmerText(
                          text: widget.badgeTitle.toUpperCase(),
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: tertiary,
                            letterSpacing: 1.2,
                            shadows: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          baseColor: tertiary,
                          highlightColor: secondary,
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      
                      AnimatedBuilder(
                        animation: _mainController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _descOpacityAnimation.value,
                            child: child,
                          );
                        },
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 300),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16, 
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            widget.badgeDescription,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: colorScheme.onBackground,
                              height: 1.6,
                            ),
                          ),
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
    );
  }
  
  Widget _buildAnimatedBadge(BuildContext context, Color tertiary, Color secondary) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        
        final pulseScale = 1.0 + (_pulseController.value * 0.06);
        
        return Stack(
          alignment: Alignment.center,
          children: [
            
            Container(
              width: 180 * pulseScale,
              height: 180 * pulseScale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    secondary.withOpacity(0.5),
                    secondary.withOpacity(0.0),
                  ],
                  stops: const [0.4, 1.0],
                ),
              ),
            ),
            
            
            Container(
              width: 160 * pulseScale,
              height: 160 * pulseScale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    tertiary.withOpacity(0.3),
                    tertiary.withOpacity(0.0),
                  ],
                  stops: const [0.6, 1.0],
                ),
              ),
            ),
            
            
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(0.2, -0.2),
                  radius: 0.9,
                  colors: [
                    Colors.white.withOpacity(0.95),
                    Colors.white.withOpacity(0.85),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: secondary.withOpacity(0.35),
                    blurRadius: 20,
                    spreadRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: secondary.withOpacity(0.7),
                  width: 3,
                ),
              ),
              child: Center(
                child: Hero(
                  tag: widget.avatarImage,
                  child: Image.asset(
                    widget.avatarImage,
                    width: 120,
                    height: 120,
                  ),
                ),
              ),
            ),
            
            
            IgnorePointer(
              child: Container(
                width: 270,
                height: 270,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 1000),
                  opacity: 0.7,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.0),
                          Colors.white.withOpacity(0.5),
                          Colors.white.withOpacity(0.0),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}


class EnhancedShimmerText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Color baseColor;
  final Color highlightColor;

  const EnhancedShimmerText({
    Key? key,
    required this.text,
    required this.style,
    required this.baseColor,
    required this.highlightColor,
  }) : super(key: key);

  @override
  State<EnhancedShimmerText> createState() => _EnhancedShimmerTextState();
}

class _EnhancedShimmerTextState extends State<EnhancedShimmerText> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: false);
    
    _animation = Tween<double>(begin: -0.3, end: 1.3).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: [
                max(0.0, _animation.value - 0.4),
                _animation.value,
                min(1.0, _animation.value + 0.4),
              ],
              tileMode: TileMode.clamp,
            ).createShader(bounds);
          },
          child: Text(
            widget.text,
            style: widget.style,
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }
}


class EnhancedParticleWidget extends StatelessWidget {
  final AnimationController controller;
  final AnimationController pulseController;
  final int index;
  final List<Color> colors;
  
  const EnhancedParticleWidget({
    Key? key,
    required this.controller,
    required this.pulseController,
    required this.index,
    required this.colors,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    
    final random = Random(index);
    final particleType = index % 5;
    final size = random.nextDouble() * 10 + 2;
    final speedFactor = random.nextDouble() * 0.8 + 0.3;
    final delayFactor = random.nextDouble() * 0.5;
    
    
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    
    double radius, angle;
    
    if (index % 3 == 0) {
      
      radius = min(screenWidth, screenHeight) * (0.1 + random.nextDouble() * 0.3);
      angle = random.nextDouble() * 2 * pi;
    } else {
      
      radius = min(screenWidth, screenHeight) * (0.3 + random.nextDouble() * 0.5);
      angle = random.nextDouble() * 2 * pi;
    }
    
    final baseOffset = Offset(
      screenWidth / 2 + cos(angle) * radius,
      screenHeight / 2 + sin(angle) * radius,
    );
    
    
    final baseColor = colors[index % colors.length];
    final hslColor = HSLColor.fromColor(baseColor);
    final Color color = HSLColor.fromAHSL(
      baseColor.opacity,
      (hslColor.hue + random.nextDouble() * 20 - 10) % 360,
      (hslColor.saturation + random.nextDouble() * 0.3 - 0.15).clamp(0.0, 1.0),
      (hslColor.lightness + random.nextDouble() * 0.3 - 0.1).clamp(0.1, 0.9),
    ).toColor();
    
    return AnimatedBuilder(
      animation: Listenable.merge([controller, pulseController]),
      builder: (context, child) {
        
        final adjustedTime = (controller.value + delayFactor) % 1.0;
        final time = adjustedTime * speedFactor;
        
        
        double floatX, floatY;
        
        if (index % 4 == 0) {
          
          final spiral = time * 6 * pi;
          final spiralRadius = 50 * time;
          floatX = cos(spiral) * spiralRadius;
          floatY = sin(spiral) * spiralRadius - (time * 100);
        } else if (index % 4 == 1) {
          
          floatX = sin(time * 3 * pi + index) * 60;
          floatY = cos(time * 2 * pi + index * 1.5) * 40 - (time * 80);
        } else if (index % 4 == 2) {
          
          final circle = time * 4 * pi;
          floatX = sin(circle) * 30 + cos(circle * 0.5) * 20;
          floatY = cos(circle) * 30 - (time * 60);
        } else {
          
          floatX = sin(time * 2 * pi + index) * 50 + cos(time * pi + index * 0.8) * 20;
          floatY = cos(time * 2 * pi + index * 1.2) * 40 - (time * 70);
        }
        
        
        if (index % 5 == 0) {
          final pulseEffect = pulseController.value * 10;
          floatX += sin(pulseEffect) * 5;
          floatY += cos(pulseEffect) * 5;
        }
        
        
        double opacity;
        
        if (index % 5 == 0) {
          
          opacity = (sin(time * pi * 3) * 0.4 + 0.6) * 0.9;
        } else if (index % 5 == 1) {
          
          opacity = sin(time * pi) * 0.7 + 0.3;
        } else {
          
          opacity = (cos(time * pi) * 0.5 + 0.5) * 0.7;
        }
        
        
        if (index % 3 == 0) {
          opacity *= (0.7 + pulseController.value * 0.3);
        }
        
        
        opacity = opacity.clamp(0.0, 0.9);
        
        
        final xPos = baseOffset.dx + floatX;
        final yPos = baseOffset.dy + floatY;
        
        
        if (xPos < -20 || xPos > screenWidth + 20 || 
            yPos < -20 || yPos > screenHeight + 20) {
          return const SizedBox.shrink(); 
        }
        
        
        double particleSize = size;
        if (index % 4 == 0) {
          particleSize *= (0.8 + pulseController.value * 0.4);
        }

        return Transform.translate(
          offset: Offset(xPos, yPos),
          child: Opacity(
            opacity: opacity,
            child: Transform.rotate(
              angle: time * pi * (index % 2 == 0 ? 1 : -1),
              child: _buildParticle(particleType, particleSize, color),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildParticle(int type, double size, Color color) {
    switch(type) {
      case 0:
        
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color,
                color.withOpacity(0.5),
              ],
              stops: const [0.3, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.5),
                blurRadius: size * 0.5,
                spreadRadius: size * 0.2,
              ),
            ],
          ),
        );
      case 1:
        
        return Container(
          width: size * 1.2,
          height: size * 1.2,
          decoration: BoxDecoration(
            color: Colors.transparent,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.7),
                blurRadius: size * 0.6,
                spreadRadius: size * 0.2,
              ),
            ],
          ),
          child: Icon(
            Icons.star,
            size: size * 1.2,
            color: color,
          ),
        );
      case 2:
        
        return Transform.rotate(
          angle: pi / 4,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(1.0),
                  color.withOpacity(0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(size * 0.2),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: size * 0.6,
                  spreadRadius: size * 0.1,
                ),
              ],
            ),
          ),
        );
      case 3:
        
        return CustomPaint(
          size: Size(size * 1.5, size * 1.5),
          painter: SparkPainter(color: color),
        );
      default:
        
        return Container(
          width: size * 0.8,
          height: size * 0.8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.9),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.8),
                blurRadius: size * 1.0,
                spreadRadius: size * 0.4,
              ),
            ],
          ),
        );
    }
  }
}


class SparkPainter extends CustomPainter {
  final Color color;
  
  SparkPainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    
    
    for (int i = 0; i < 4; i++) {
      final angle = i * pi / 2;
      final pointA = center;
      final pointB = Offset(
        center.dx + cos(angle) * radius,
        center.dy + sin(angle) * radius,
      );
      canvas.drawLine(pointA, pointB, paint);
    }
    
    
    for (int i = 0; i < 4; i++) {
      final angle = (i * pi / 2) + (pi / 4);
      final pointA = center;
      final pointB = Offset(
        center.dx + cos(angle) * radius * 0.7,
        center.dy + sin(angle) * radius * 0.7,
      );
      canvas.drawLine(pointA, pointB, paint);
    }
    
    
    final centerPaint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
    
    canvas.drawCircle(center, radius * 0.2, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
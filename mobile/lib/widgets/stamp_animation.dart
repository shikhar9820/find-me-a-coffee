import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class StampAnimationDialog extends StatefulWidget {
  final String cafeName;
  final int currentStamps;
  final int totalStamps;
  final bool isNewCafe;

  const StampAnimationDialog({
    super.key,
    required this.cafeName,
    required this.currentStamps,
    required this.totalStamps,
    this.isNewCafe = false,
  });

  @override
  State<StampAnimationDialog> createState() => _StampAnimationDialogState();
}

class _StampAnimationDialogState extends State<StampAnimationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 40,
      ),
    ]).animate(_controller);

    _rotateAnimation = Tween<double>(begin: -0.1, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    // Auto close after animation
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canRedeem = widget.currentStamps >= widget.totalStamps;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform.rotate(
                angle: _rotateAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Stamp icon with animation
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: canRedeem
                              ? AppTheme.success.withOpacity(0.1)
                              : AppTheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          canRedeem ? Icons.celebration : Icons.coffee,
                          size: 50,
                          color: canRedeem ? AppTheme.success : AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Title
                      Text(
                        canRedeem ? 'Reward Ready!' : 'Stamp Collected!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: canRedeem ? AppTheme.success : AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Cafe name
                      Text(
                        widget.cafeName,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      if (widget.isNewCafe) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'First stamp here!',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Progress
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          widget.totalStamps > 10 ? 10 : widget.totalStamps,
                          (index) {
                            final isFilled = index < widget.currentStamps;
                            final isLatest = index == widget.currentStamps - 1;

                            return Container(
                              width: 24,
                              height: 24,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isFilled
                                    ? (canRedeem
                                        ? AppTheme.success
                                        : AppTheme.primary)
                                    : Colors.grey.shade200,
                                border: isLatest
                                    ? Border.all(
                                        color: AppTheme.accent,
                                        width: 3,
                                      )
                                    : null,
                              ),
                              child: isFilled
                                  ? const Icon(
                                      Icons.coffee,
                                      color: Colors.white,
                                      size: 12,
                                    )
                                  : null,
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Progress text
                      Text(
                        '${widget.currentStamps}/${widget.totalStamps}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      if (canRedeem) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Go to Rewards to claim your free coffee!',
                          style: TextStyle(
                            color: AppTheme.success,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ] else ...[
                        const SizedBox(height: 8),
                        Text(
                          '${widget.totalStamps - widget.currentStamps} more to go!',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

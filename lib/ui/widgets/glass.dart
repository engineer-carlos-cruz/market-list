import 'dart:ui';

import 'package:flutter/material.dart';

class DecoratedBackground extends StatelessWidget {
  const DecoratedBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFFBF5F1),
                const Color(0xFFF4E6DD),
                scheme.primary.withValues(alpha: 0.10),
              ],
            ),
          ),
        ),
        Positioned(
          top: -80,
          right: -60,
          child: _Blob(
            size: 260,
            colors: [
              scheme.primary.withValues(alpha: 0.30),
              scheme.primary.withValues(alpha: 0),
            ],
          ),
        ),
        Positioned(
          bottom: -100,
          left: -70,
          child: _Blob(
            size: 300,
            colors: [
              scheme.secondaryContainer.withValues(alpha: 0.55),
              scheme.secondaryContainer.withValues(alpha: 0),
            ],
          ),
        ),
        Positioned(
          top: 220,
          left: 40,
          child: _Blob(
            size: 160,
            colors: [
              scheme.tertiary.withValues(alpha: 0.18),
              scheme.tertiary.withValues(alpha: 0),
            ],
          ),
        ),
        child,
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.colors});

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: colors,
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    this.borderRadius = 24,
    this.padding = const EdgeInsets.all(24),
    this.blurSigma = 14,
    required this.child,
  });

  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double blurSigma;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: radius,
              color: Colors.white.withValues(alpha: 0.58),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.65),
                width: 1.2,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
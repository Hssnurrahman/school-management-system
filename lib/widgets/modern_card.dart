import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Modern card with glassmorphism effect and animations
class ModernCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final Color? backgroundColor;
  final Gradient? gradient;
  final List<BoxShadow>? boxShadow;
  final Border? border;
  final double? width;
  final double? height;
  final Duration animationDuration;
  final Curve animationCurve;

  const ModernCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(20),
    this.margin = EdgeInsets.zero,
    this.borderRadius = 20,
    this.backgroundColor,
    this.gradient,
    this.boxShadow,
    this.border,
    this.width,
    this.height,
    this.animationDuration = const Duration(milliseconds: 200),
    this.animationCurve = Curves.easeOutCubic,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Widget cardContent = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient != null 
            ? null 
            : (backgroundColor ?? (isDark ? AppColors.darkCard : AppColors.lightCard)),
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ?? Border.all(
          color: isDark 
              ? Colors.white.withValues(alpha: 0.06) 
              : AppColors.lightBorder,
          width: 1,
        ),
        boxShadow: boxShadow ?? [
          BoxShadow(
            color: isDark 
                ? Colors.black.withValues(alpha: 0.2) 
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return AnimatedScale(
        scale: 1.0,
        duration: animationDuration,
        curve: animationCurve,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(borderRadius),
            child: cardContent,
          ),
        ),
      );
    }

    return cardContent;
  }
}

/// Gradient card with modern styling
class GradientCard extends StatelessWidget {
  final Widget child;
  final Gradient gradient;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;

  const GradientCard({
    super.key,
    required this.child,
    required this.gradient,
    this.onTap,
    this.padding = const EdgeInsets.all(20),
    this.margin = EdgeInsets.zero,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      margin: margin,
      borderRadius: borderRadius,
      gradient: gradient,
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.2),
        width: 1,
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

/// Glassmorphism card for overlay effects
class GlassCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final double opacity;

  const GlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(20),
    this.margin = EdgeInsets.zero,
    this.borderRadius = 24,
    this.opacity = 0.7,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ModernCard(
      onTap: onTap,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      backgroundColor: isDark 
          ? AppColors.darkCard.withValues(alpha: opacity)
          : Colors.white.withValues(alpha: opacity),
      border: Border.all(
        color: isDark 
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.5),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: isDark 
              ? Colors.black.withValues(alpha: 0.3)
              : Colors.black.withValues(alpha: 0.04),
          blurRadius: 30,
          offset: const Offset(0, 10),
        ),
      ],
      child: child,
    );
  }
}

/// Stat card for dashboard
class StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final Gradient? gradient;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ModernCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: gradient ?? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.2),
                  color.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: color.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkText : AppColors.lightText,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Feature card with icon and label
class FeatureCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isCompact;

  const FeatureCard({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ModernCard(
      onTap: onTap,
      padding: isCompact 
          ? const EdgeInsets.all(12) 
          : const EdgeInsets.all(16),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: isCompact 
                ? const EdgeInsets.all(10) 
                : const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: color.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Icon(icon, color: color, size: isCompact ? 20 : 24),
          ),
          if (!isCompact) const Spacer(),
          Text(
            label,
            style: TextStyle(
              fontSize: isCompact ? 12 : 14,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkText : AppColors.lightText,
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Info card with leading icon and details
class InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const InfoCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ModernCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderRadius: 16,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark 
                          ? AppColors.darkTextSecondary 
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

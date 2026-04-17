import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

/// 🎨 زر عودة بتصميم فخم (Glassmorphism)
class MushafHomeButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Color primaryColor;

  const MushafHomeButton({
    super.key,
    required this.onPressed,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          onPressed();
        },
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: primaryColor.withValues(alpha: 0.25), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(19),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Center(
                child: Icon(
                  Icons.home_rounded,
                  color: primaryColor,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 🔘 زر أيقونة بتنسيق فخم
class MushafIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;
  final double size;

  const MushafIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? const Color(0xFFD4A947);
    return IconButton(
      icon: Icon(icon, color: effectiveColor, size: size),
      onPressed: onPressed,
      splashColor: effectiveColor.withValues(alpha: 0.15),
      highlightColor: effectiveColor.withValues(alpha: 0.05),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }
}

/// 🎩 خيارات القائمة البريميوم
class MushafPremiumOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color goldColor;
  final Color lightGoldColor;

  const MushafPremiumOption({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.goldColor,
    required this.lightGoldColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(25),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: goldColor.withValues(alpha: 0.4),
                width: 1.5,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  goldColor.withValues(alpha: 0.1),
                  goldColor.withValues(alpha: 0.05),
                ],
              ),
            ),
            child: Icon(icon, color: goldColor, size: 26),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: GoogleFonts.amiri(
            color: lightGoldColor.withValues(alpha: 0.8),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

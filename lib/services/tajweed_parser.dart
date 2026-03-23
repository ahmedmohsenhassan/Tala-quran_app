import 'package:flutter/material.dart';

/// محلل نصوص التجويد
/// Parser for Tajweed-encoded HTML strings into Flutter InlineSpans
class TajweedParser {
  // خريطة الألوان المتميزة لأحكام التجويد
  // Premium Color Map for Tajweed Rules
  static final Map<String, Color> _ruleColors = {
    'tajweed-ghunnah': const Color(0xFFFF4848), // أحمر فيني (Ghunnah)
    'tajweed-ikhfa': const Color(0xFFFF9800),    // برتقالي (Ikhfa)
    'tajweed-ikhfa_shafawi': const Color(0xFFFFB74D), 
    'tajweed-qalqalah': const Color(0xFF4CAF50), // أخضر زمردي (Qalqalah)
    'tajweed-madda': const Color(0xFF2196F3),    // أزرق سماوي (Mad)
    'tajweed-madda_normal': const Color(0xFF64B5F6),
    'tajweed-madda_permissible': const Color(0xFF1976D2),
    'tajweed-madda_necessary': const Color(0xFF0D47A1),
    'tajweed-iqlab': const Color(0xFF9C27B0),    // بنفسجي (Iqlab)
    'tajweed-idgham': const Color(0xFF9E9E9E),   // رمادي (Idgham - usually ignored color-wise)
    'tajweed-idgham_nos_ghunnah': const Color(0xFF757575),
  };

  /// تحويل نص التجويد (HTML) إلى قائمة من الـ Spans
  /// Convert HTML Tajweed text to a list of InlineSpans
  static List<InlineSpan> parse(String html, TextStyle baseStyle) {
    List<InlineSpan> spans = [];
    
    // Regex to match <span class="xxx">...</span> or plain text
    // Example: <span class="tajweed-ghunnah">نَّ</span>
    final RegExp regExp = RegExp(r'<span class="([^"]+)">([^<]+)</span>|([^<]+)');
    final Iterable<RegExpMatch> matches = regExp.allMatches(html);

    for (final match in matches) {
      if (match.group(1) != null) {
        // Tagged segment: <span class="xxx">...</span>
        final String className = match.group(1)!;
        final String text = match.group(2)!;
        final Color? color = _ruleColors[className];

        spans.add(TextSpan(
          text: text,
          style: baseStyle.copyWith(
            color: color ?? baseStyle.color,
            fontWeight: color != null ? FontWeight.bold : baseStyle.fontWeight,
          ),
        ));
      } else if (match.group(3) != null) {
        // Plain text segment
        spans.add(TextSpan(
          text: match.group(3)!,
          style: baseStyle,
        ));
      }
    }

    return spans;
  }

  /// الحصول على شرح بسيط للحكم بناءً على اسم الكلاس
  /// Get a brief explanation for a tajweed rule based on its class name
  static String getRuleExplanation(String className) {
    switch (className) {
      case 'tajweed-ghunnah': return 'غنة: صوت يخرج من الخيشوم.';
      case 'tajweed-qalqalah': return 'قلقلة: اضطراب الحرف في مخرجه عند النطق به ساكناً.';
      case 'tajweed-ikhfa': return 'إخفاء: نطق الحرف بصفة بين الإظهار والإدغام.';
      case 'tajweed-madda': return 'مد: إطالة الصوت بحرف من حروف المد.';
      case 'tajweed-iqlab': return 'إقلاب: قلب النون الساكنة أو التنوين ميماً.';
      default: return 'حكم تجويدي.';
    }
  }
}

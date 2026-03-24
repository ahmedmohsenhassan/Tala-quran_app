import 'dart:math';
import '../utils/quran_page_helper.dart';

class SpiritualInsight {
  final String title;
  final String content;
  final InsightType type;
  final String? verseKey;

  const SpiritualInsight({
    required this.title,
    required this.content,
    required this.type,
    this.verseKey,
  });
}

enum InsightType {
  reflection,
  thematic,
  wisdom,
  context,
}

class TalaAIService {
  static final TalaAIService _instance = TalaAIService._internal();
  factory TalaAIService() => _instance;
  TalaAIService._internal();

  final Random _random = Random();

  /// 🧠 Generates spiritual insights for the current page
  Future<List<SpiritualInsight>> getInsightsForPage(int pageNumber) async {
    final surahName = QuranPageHelper.getSurahNameForPage(pageNumber);
    final surahNumber = QuranPageHelper.getSurahForPage(pageNumber);
    
    // Simulate complex AI processing delay for premium feel
    await Future.delayed(const Duration(milliseconds: 800));

    final List<SpiritualInsight> insights = [];

    // 1. Contextual Insight
    insights.add(SpiritualInsight(
      title: 'سياق سورة $surahName',
      content: _getSurahContext(surahNumber),
      type: InsightType.context,
    ));

    // 2. Thematic Insight
    insights.add(SpiritualInsight(
      title: 'المحور الرئيسي لهذه الصفحة',
      content: _getThematicFocus(pageNumber),
      type: InsightType.thematic,
    ));

    // 3. Reflection (Tadabbur) Prompt
    insights.add(SpiritualInsight(
      title: 'وقفة تدبر (تأمل)',
      content: _getReflectionPrompt(pageNumber),
      type: InsightType.reflection,
    ));

    // 4. Modern Wisdom
    insights.add(SpiritualInsight(
      title: 'تطبيق في حياتك اليومية',
      content: _getDailyWisdom(pageNumber),
      type: InsightType.wisdom,
    ));

    return insights;
  }

  String _getSurahContext(int surah) {
    // Map specific surah context (Knowledge Base)
    switch (surah) {
      case 1: return 'سورة الفاتحة هي أعظم سورة في القرآن، وهي مناجاة بين العبد وربه، مطلعها تحميد وثناء، ووسطها عهد، وختامها دعاء.';
      case 2: return 'سورة البقرة هي أطول سور القرآن، تتناول التشريعات الكبرى ونبذة عن تاريخ الأمم السابقة وأهمية ميثاق الاستخلاف في الأرض.';
      default: return 'سورة $surah تتنزل لتثبيت فؤاد المؤمنين وتقديم حلول ربانية لمشكلات النفس والمجتمع.';
    }
  }

  String _getThematicFocus(int page) {
    if (page <= 5) return 'تأسيس العقيدة والتفريق بين صفات المؤمنين والمنافقين والكافرين.';
    if (page <= 10) return 'دعوة بني إسرائيل لتذكر نعم الله والتحذير من مغبة نقض العهود.';
    if (page > 600) return 'مرحلة الختام وتثبيت العقيدة في القلوب والاستعاذة من وساوس النفس.';
    return 'التركيز على بناء النفس وتذكير الإنسان بمسؤوليته تجاه الخالق والمجتمع.';
  }

  String _getReflectionPrompt(int page) {
    final prompts = [
      'ما هي الآية التي لامست قلبك اليوم في هذه الصفحة؟ وكيف يمكنك تطبيقها في موقف ستواجهه غداً؟',
      'تأمل في أسماء الله الحسنى التي ذُكرت في هذه الآيات، وكيف تتجلى في تفاصيل حياتك الآن؟',
      'لو كانت هذه الصفحة رسالة خاصة لك من الله، فما هو التوجيه الأهم الذي استنبطته؟',
      'كيف تصف شعورك وأنت تقرأ عن رحمة الله في هذه الآيات؟',
    ];
    return prompts[_random.nextInt(prompts.length)];
  }

  String _getDailyWisdom(int page) {
    final wisdoms = [
      'الاستقامة في صغائر الأمور تقودك للثبات في كبائرها. فاجعل وردك اليوم مصدراً لثباتك.',
      'كن كالمصحف؛ جليلاً في صمتك، مؤثراً في حضورك، رحيماً في تعاملك.',
      'التدبر لا يحتاج إلى علم غزير فحسب، بل يحتاج إلى قلب حاضر ونية صادقة للتغيير.',
      'ما ضاق طريق في وجهك إلا وجعل الله في كتابه مخرجاً، فبحث عن مخرجك في آيات اليوم.',
    ];
    return wisdoms[_random.nextInt(wisdoms.length)];
  }
}

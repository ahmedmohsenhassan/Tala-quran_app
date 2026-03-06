import 'dart:convert';
import 'package:flutter/services.dart';

/// خدمة جلب نص القرآن الكريم من ملفات JSON
/// Service to fetch Quranic text from local JSON assets
class QuranTextService {
  static final QuranTextService _instance = QuranTextService._internal();
  factory QuranTextService() => _instance;
  QuranTextService._internal();

  /// جلب بيانات السورة بالكامل (بما في ذلك الآيات)
  /// Fetch complete Surah data including verses
  Future<Map<String, dynamic>> getSurahDetail(int surahNumber) async {
    try {
      // نبحث عن الملف بناءً على الرقم (مؤقتاً للنموذج)
      // في التطبيق الفعلي، سنحتاج لخريطة (Map) تربط الرقم باسم الملف الصحيح
      String fileName = _getFileName(surahNumber);

      final String response =
          await rootBundle.loadString('assets/surahs/$fileName.json');
      final data = await json.decode(response);
      return data;
    } catch (e) {
      return {
        "error": "فشل تحميل البيانات",
        "ayahs": [
          {"number": 1, "text": "عذراً، لم نتمكن من تحميل نص السورة حالياً."}
        ]
      };
    }
  }

  String _getFileName(int number) {
    // خريطة بسيطة للأسماء الموجودة حالياً في المجلد
    final names = {
      1: "Al-Fatiha",
      2: "Al-Baqarah",
      3: "Aal-i-Imraan",
      // ... يمكن إضافة الباقي هنا
    };
    return names[number] ?? "Al-Fatiha";
  }
}

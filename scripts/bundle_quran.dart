// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';

void main() async {
  final dio = Dio();
  final outDir = Directory('assets/mushaf/data');
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  print('🚀 Starting Quran Data Bundling (604 Pages)...');

  for (int p = 1; p <= 604; p++) {
    try {
      print('📖 Fetching Page $p...');
      
      // 1. Fetch Verses
      final vResponse = await dio.get(
        'https://api.quran.com/api/v4/quran/verses/uthmani',
        queryParameters: {
          'page_number': p,
          'fields': 'text_uthmani,verse_key,line_number,page_number',
        },
      );
      
      if (vResponse.statusCode == 200) {
        final vFile = File('${outDir.path}/verses_p$p.json');
        await vFile.writeAsString(jsonEncode(vResponse.data['verses']));
      }

      // 2. Fetch Words
      final wResponse = await dio.get(
        'https://api.quran.com/api/v4/verses/by_page/$p',
        queryParameters: {
          'words': 'true',
          'word_fields': 'text_uthmani,line_number,location',
        },
      );
      
      if (wResponse.statusCode == 200) {
        final wFile = File('${outDir.path}/words_p$p.json');
        await wFile.writeAsString(jsonEncode(wResponse.data['verses']));
      }

      print('✅ Page $p Saved.');
      
      // Sleep slightly to avoid rate limiting
      await Future.delayed(const Duration(milliseconds: 100));
      
    } catch (e) {
      print('❌ Error on Page $p: $e');
    }
  }

  print('✨ Bundling Complete! All 604 pages are now offline-ready.');
}

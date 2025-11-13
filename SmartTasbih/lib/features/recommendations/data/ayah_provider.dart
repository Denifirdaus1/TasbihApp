import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran/quran.dart' as quran;

class DailyAyah {
  const DailyAyah({
    required this.surahNumber,
    required this.verseNumber,
    required this.arabic,
    required this.translation,
    required this.surahArabicName,
    required this.surahLatinName,
  });

  final int surahNumber;
  final int verseNumber;
  final String arabic;
  final String translation;
  final String surahArabicName;
  final String surahLatinName;
}

final ayahOfTheDayProvider = Provider<DailyAyah>((ref) {
  final date = DateTime.now();
  final dayOfYear =
      date.difference(DateTime(date.year)).inDays; // zero-based ordinal

  final surahNumber = (dayOfYear % quran.totalSurahCount) + 1;
  final verseTotal = quran.getVerseCount(surahNumber);
  final verseNumber = (dayOfYear % verseTotal) + 1;

  return DailyAyah(
    surahNumber: surahNumber,
    verseNumber: verseNumber,
    arabic: quran.getVerse(
      surahNumber,
      verseNumber,
      verseEndSymbol: true,
    ),
    translation: quran.getVerseTranslation(
      surahNumber,
      verseNumber,
      translation: quran.Translation.indonesian,
    ),
    surahArabicName: quran.getSurahNameArabic(surahNumber),
    surahLatinName: quran.getSurahNameEnglish(surahNumber),
  );
});

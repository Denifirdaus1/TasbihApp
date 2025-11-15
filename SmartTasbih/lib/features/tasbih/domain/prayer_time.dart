enum PrayerTime {
  fajr('Subuh', 'fajr'),
  dhuhr('Dhuhur', 'dhuhr'),
  asr('Ashar', 'asr'),
  maghrib('Maghrib', 'maghrib'),
  isha('Isya', 'isha');

  const PrayerTime(this.arabicName, this.value);
  
  final String arabicName;
  final String value;

  static PrayerTime? fromString(String? value) {
    if (value == null) return null;
    return PrayerTime.values.firstWhere(
      (time) => time.value == value,
      orElse: () => PrayerTime.fajr,
    );
  }
}

class DefaultPrayerCollections {
  static const List<Map<String, dynamic>> collections = [
    {
      'name': 'Dzikir Subuh',
      'description': 'Dzikir setelah sholat Subuh',
      'prayer_time': 'fajr',
      'icon': 'wb_twilight',
      'color': '#FF6B6B',
    },
    {
      'name': 'Dzikir Dhuhur',
      'description': 'Dzikir setelah sholat Dhuhur',
      'prayer_time': 'dhuhr',
      'icon': 'wb_sunny',
      'color': '#FFA726',
    },
    {
      'name': 'Dzikir Ashar',
      'description': 'Dzikir setelah sholat Ashar',
      'prayer_time': 'asr',
      'icon': 'wb_cloudy',
      'color': '#FFB74D',
    },
    {
      'name': 'Dzikir Maghrib',
      'description': 'Dzikir setelah sholat Maghrib',
      'prayer_time': 'maghrib',
      'icon': 'nights_stay',
      'color': '#9575CD',
    },
    {
      'name': 'Dzikir Isya',
      'description': 'Dzikir setelah sholat Isya',
      'prayer_time': 'isha',
      'icon': 'brightness_3',
      'color': '#5C6BC0',
    },
  ];

  static const List<Map<String, dynamic>> defaultDhikrItems = [
    {
      'text': 'سُبْحَانَ اللهِ',
      'translation': 'Maha Suci Allah',
      'target_count': 33,
    },
    {
      'text': 'اَلْحَمْدُ لِلّٰهِ',
      'translation': 'Segala Puji Bagi Allah',
      'target_count': 33,
    },
    {
      'text': 'اللّٰهُ أَكْبَرُ',
      'translation': 'Allah Maha Besar',
      'target_count': 33,
    },
  ];

  static const List<Map<String, dynamic>> defaultTimeDhikrItems = [
    {
      'text': 'أَعُوذُ بِاللّٰهِ مِنَ الشَّيْطَانِ الرَّجِيمِ',
      'translation': 'Aku berlindung kepada Allah dari godaan syaitan yang terkutuk',
      'target_count': 1,
    },
    {
      'text': 'بِسْمِ اللّٰهِ الرَّحْمَٰنِ الرَّحِيمِ',
      'translation': 'Dengan menyebut nama Allah yang Maha Pengasih lagi Maha Penyayang',
      'target_count': 1,
    },
    {
      'text': 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
      'translation': 'Segala puji bagi Allah, Tuhan semesta alam',
      'target_count': 1,
    },
    {
      'text': 'سُبْحَانَ اللهِ',
      'translation': 'Maha Suci Allah',
      'target_count': 33,
    },
    {
      'text': 'اَلْحَمْدُ لِلّٰهِ',
      'translation': 'Segala Puji Bagi Allah',
      'target_count': 33,
    },
    {
      'text': 'اللّٰهُ أَكْبَرُ',
      'translation': 'Allah Maha Besar',
      'target_count': 33,
    },
    {
      'text': 'لَا إِلَٰهَ إِلَّا اللّٰهُ وَحْدَهُ لَا شَرِيكَ لَهُ',
      'translation': 'Tiada tuhan selain Allah, Yang Maha Esa, tidak ada sekutu bagi-Nya',
      'target_count': 10,
    },
  ];
}

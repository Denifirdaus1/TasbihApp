import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;

class MoodOption {
  const MoodOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.recommendations,
  });

  final String id;
  final String title;
  final String subtitle;
  final List<ZikirRecommendation> recommendations;
}

class ZikirRecommendation {
  const ZikirRecommendation({
    required this.name,
    required this.description,
    required this.translation,
  });

  final String name;
  final String description;
  final String translation;
}

const _moods = [
  MoodOption(
    id: 'cemas',
    title: 'Cemas',
    subtitle: 'Tenangkan hati',
    recommendations: [
      ZikirRecommendation(
        name: 'Hasbunallahu wa ni\'mal wakil',
        description: 'Meneguhkan tawakal saat hati gelisah.',
        translation:
            'Cukuplah Allah sebagai penolong kami dan sebaik-baik pelindung.',
      ),
      ZikirRecommendation(
        name: 'La ilaha illa Anta Subhanaka inni kuntu minaz-zalimin',
        description: 'Doa Nabi Yunus saat terhimpit masalah.',
        translation:
            'Tiada ilah selain Engkau. Mahasuci Engkau, sungguh aku termasuk orang yang zalim.',
      ),
    ],
  ),
  MoodOption(
    id: 'syukur',
    title: 'Syukur',
    subtitle: 'Rayakan nikmat',
    recommendations: [
      ZikirRecommendation(
        name: 'Alhamdulillah',
        description: 'Merefleksikan nikmat kecil menjadi besar.',
        translation: 'Segala puji bagi Allah.',
      ),
      ZikirRecommendation(
        name: 'Shalawat',
        description: 'Menghadirkan ketenangan dan berkah.',
        translation:
            'Allahumma shalli \'ala Sayyidina Muhammad wa \'ala ali Sayyidina Muhammad.',
      ),
    ],
  ),
  MoodOption(
    id: 'lelah',
    title: 'Lelah',
    subtitle: 'Isi ulang energi ruhani',
    recommendations: [
      ZikirRecommendation(
        name: 'Astaghfirullah',
        description: 'Membersihkan hati dari beban.',
        translation: 'Aku memohon ampun kepada Allah.',
      ),
      ZikirRecommendation(
        name: 'Ya Hayyu Ya Qayyum',
        description: 'Memohon kekuatan atas segala aktivitas.',
        translation: 'Wahai Yang Maha Hidup dan Maha Berdiri Sendiri.',
      ),
    ],
  ),
];

final moodOptionsProvider = Provider<List<MoodOption>>((ref) => _moods);

final selectedMoodProvider = StateProvider<String?>((ref) => _moods.first.id);

final zikirRecommendationProvider = Provider<List<ZikirRecommendation>>((ref) {
  final selectedId = ref.watch(selectedMoodProvider);
  final moods = ref.watch(moodOptionsProvider);
  final mood = moods.firstWhere(
    (option) => option.id == selectedId,
    orElse: () => moods.first,
  );
  return mood.recommendations;
});

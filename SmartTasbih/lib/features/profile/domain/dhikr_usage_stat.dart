class DhikrUsageStat {
  const DhikrUsageStat({
    required this.dhikrItemId,
    required this.text,
    required this.totalCount,
    this.collectionName,
    this.translation,
    this.lastUsedDate,
  });

  final String dhikrItemId;
  final String text;
  final int totalCount;
  final String? collectionName;
  final String? translation;
  final DateTime? lastUsedDate;

  factory DhikrUsageStat.fromMap(Map<String, dynamic> map) {
    return DhikrUsageStat(
      dhikrItemId: map['dhikr_item_id'] as String,
      text: map['dhikr_text'] as String? ?? 'Dzikir',
      totalCount: (map['total_count'] as num?)?.toInt() ?? 0,
      collectionName: map['collection_name'] as String?,
      translation: map['dhikr_translation'] as String?,
      lastUsedDate: map['last_used_date'] != null
          ? DateTime.tryParse(map['last_used_date'] as String)
          : null,
    );
  }
}

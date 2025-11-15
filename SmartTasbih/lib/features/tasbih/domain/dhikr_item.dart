class DhikrItem {
  const DhikrItem({
    required this.id,
    required this.collectionId,
    required this.text,
    this.translation,
    this.targetCount = 33,
    required this.orderIndex,
    this.createdAt,
  });

  final String id;
  final String collectionId;
  final String text;
  final String? translation;
  final int targetCount;
  final int orderIndex;
  final DateTime? createdAt;

  factory DhikrItem.fromMap(Map<String, dynamic> map) {
    return DhikrItem(
      id: map['id'] as String,
      collectionId: map['collection_id'] as String,
      text: map['text'] as String,
      translation: map['translation'] as String?,
      targetCount: (map['target_count'] as num?)?.toInt() ?? 33,
      orderIndex: (map['order_index'] as num?)?.toInt() ?? 0,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'collection_id': collectionId,
      'text': text,
      'translation': translation,
      'target_count': targetCount,
      'order_index': orderIndex,
      'created_at': createdAt?.toIso8601String(),
    }..removeWhere((_, value) => value == null);
  }

  DhikrItem copyWith({
    String? text,
    String? translation,
    int? targetCount,
    int? orderIndex,
  }) {
    return DhikrItem(
      id: id,
      collectionId: collectionId,
      text: text ?? this.text,
      translation: translation ?? this.translation,
      targetCount: targetCount ?? this.targetCount,
      orderIndex: orderIndex ?? this.orderIndex,
      createdAt: createdAt,
    );
  }
}
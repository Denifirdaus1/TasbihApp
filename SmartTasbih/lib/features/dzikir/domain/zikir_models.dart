class ZikirMaster {
  const ZikirMaster({
    required this.id,
    required this.name,
    this.arabicText,
    this.translation,
    this.fadilah,
  });

  final int id;
  final String name;
  final String? arabicText;
  final String? translation;
  final String? fadilah;

  factory ZikirMaster.fromMap(Map<String, dynamic> map) {
    return ZikirMaster(
      id: map['id'] as int,
      name: map['name'] as String,
      arabicText: map['arabic_text'] as String?,
      translation: map['translation'] as String?,
      fadilah: map['fadilah_content'] as String?,
    );
  }
}

class UserZikirCollection {
  const UserZikirCollection({
    required this.id,
    required this.targetCount,
    this.zikirId,
    this.customName,
    this.master,
  });

  final int id;
  final int targetCount;
  final int? zikirId;
  final String? customName;
  final ZikirMaster? master;

  String get displayName => customName ?? master?.name ?? 'Zikir Tanpa Nama';

  factory UserZikirCollection.fromMap(Map<String, dynamic> map) {
    return UserZikirCollection(
      id: map['id'] as int,
      targetCount: (map['target_count'] as num?)?.toInt() ?? 100,
      zikirId: map['zikir_id'] as int?,
      customName: map['custom_name'] as String?,
      master: map['zikir_master'] == null
          ? null
          : ZikirMaster.fromMap(
              Map<String, dynamic>.from(
                map['zikir_master'] as Map<String, dynamic>,
              ),
            ),
    );
  }
}

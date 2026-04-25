class Profile {
  final String? name;
  final String? dob;
  final String? phone;
  final int createdAt;
  final String currencySymbol;
  final String? alarmSoundPath;
  final String? alarmSoundName;

  const Profile({
    this.name,
    this.dob,
    this.phone,
    required this.createdAt,
    this.currencySymbol = '₹',
    this.alarmSoundPath,
    this.alarmSoundName,
  });

  bool get isEmpty => (name == null || name!.trim().isEmpty)
      && (dob == null || dob!.trim().isEmpty)
      && (phone == null || phone!.trim().isEmpty);

  int? get age {
    if (dob == null || dob!.isEmpty) return null;
    final d = DateTime.tryParse(dob!);
    if (d == null) return null;
    final now = DateTime.now();
    var a = now.year - d.year;
    if (now.month < d.month || (now.month == d.month && now.day < d.day)) a--;
    return a < 0 ? null : a;
  }

  Profile copyWith({
    String? name,
    String? dob,
    String? phone,
    int? createdAt,
    String? currencySymbol,
    String? alarmSoundPath,
    String? alarmSoundName,
    bool clearName = false,
    bool clearDob = false,
    bool clearPhone = false,
    bool clearAlarmSound = false,
  }) =>
      Profile(
        name: clearName ? null : (name ?? this.name),
        dob: clearDob ? null : (dob ?? this.dob),
        phone: clearPhone ? null : (phone ?? this.phone),
        createdAt: createdAt ?? this.createdAt,
        currencySymbol: currencySymbol ?? this.currencySymbol,
        alarmSoundPath: clearAlarmSound ? null : (alarmSoundPath ?? this.alarmSoundPath),
        alarmSoundName: clearAlarmSound ? null : (alarmSoundName ?? this.alarmSoundName),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'dob': dob,
        'phone': phone,
        'createdAt': createdAt,
        'currencySymbol': currencySymbol,
        if (alarmSoundPath != null) 'alarmSoundPath': alarmSoundPath,
        if (alarmSoundName != null) 'alarmSoundName': alarmSoundName,
      };

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        name: j['name'] as String?,
        dob: j['dob'] as String?,
        phone: j['phone'] as String?,
        createdAt: (j['createdAt'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
        currencySymbol: (j['currencySymbol'] as String?) ?? '₹',
        alarmSoundPath: j['alarmSoundPath'] as String?,
        alarmSoundName: j['alarmSoundName'] as String?,
      );
}

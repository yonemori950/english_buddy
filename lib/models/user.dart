class User {
  final String uid;
  final String name;
  final int level;
  final int exp;
  final Map<String, Map<String, int>> scores;
  final DateTime updated;

  User({
    required this.uid,
    required this.name,
    required this.level,
    required this.exp,
    required this.scores,
    required this.updated,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['uid'] as String,
      name: json['name'] as String,
      level: json['level'] as int,
      exp: json['exp'] as int,
      scores: Map<String, Map<String, int>>.from(
        (json['scores'] as Map).map(
          (key, value) => MapEntry(
            key as String,
            Map<String, int>.from(value as Map),
          ),
        ),
      ),
      updated: DateTime.parse(json['updated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'level': level,
      'exp': exp,
      'scores': scores,
      'updated': updated.toIso8601String(),
    };
  }

  User copyWith({
    String? uid,
    String? name,
    int? level,
    int? exp,
    Map<String, Map<String, int>>? scores,
    DateTime? updated,
  }) {
    return User(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      level: level ?? this.level,
      exp: exp ?? this.exp,
      scores: scores ?? this.scores,
      updated: updated ?? this.updated,
    );
  }
}

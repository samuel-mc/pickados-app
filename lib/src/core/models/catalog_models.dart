class CatalogItem {
  CatalogItem({
    required this.id,
    required this.name,
    required this.active,
  });

  factory CatalogItem.fromJson(Map<String, dynamic> json) {
    return CatalogItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      active: json['active'] == true,
    );
  }

  final int id;
  final String name;
  final bool active;
}

class CompetitionItem {
  CompetitionItem({
    required this.id,
    required this.name,
    required this.active,
    required this.sportId,
    required this.sportName,
  });

  factory CompetitionItem.fromJson(Map<String, dynamic> json) {
    return CompetitionItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      active: json['active'] == true,
      sportId: (json['sportId'] as num?)?.toInt() ?? 0,
      sportName: (json['sportName'] ?? '').toString(),
    );
  }

  final int id;
  final String name;
  final bool active;
  final int sportId;
  final String sportName;
}

class TeamItem {
  TeamItem({
    required this.id,
    required this.name,
    required this.active,
    required this.competitionId,
    required this.competitionName,
    required this.sportId,
    required this.sportName,
  });

  factory TeamItem.fromJson(Map<String, dynamic> json) {
    return TeamItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      active: json['active'] == true,
      competitionId: (json['competitionId'] as num?)?.toInt() ?? 0,
      competitionName: (json['competitionName'] ?? '').toString(),
      sportId: (json['sportId'] as num?)?.toInt() ?? 0,
      sportName: (json['sportName'] ?? '').toString(),
    );
  }

  final int id;
  final String name;
  final bool active;
  final int competitionId;
  final String competitionName;
  final int sportId;
  final String sportName;
}

class SportsbookItem {
  SportsbookItem({
    required this.id,
    required this.name,
    required this.active,
  });

  factory SportsbookItem.fromJson(Map<String, dynamic> json) {
    return SportsbookItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      active: json['active'] == true,
    );
  }

  final int id;
  final String name;
  final bool active;
}

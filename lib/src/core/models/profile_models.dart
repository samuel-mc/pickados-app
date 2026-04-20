import 'catalog_models.dart';

class MeProfile {
  MeProfile({
    required this.id,
    required this.name,
    required this.lastname,
    required this.username,
    required this.email,
    required this.bio,
    required this.avatarUrl,
    required this.preferredCompetitions,
    required this.preferredTeams,
  });

  factory MeProfile.fromJson(Map<String, dynamic> json) {
    final rawCompetitions = json['preferredCompetitions'];
    final rawTeams = json['preferredTeams'];

    return MeProfile(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      lastname: (json['lastname'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      bio: json['bio']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      preferredCompetitions: rawCompetitions is List
          ? rawCompetitions
              .whereType<Map>()
              .map(
                (item) => CompetitionItem.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList()
          : [],
      preferredTeams: rawTeams is List
          ? rawTeams
              .whereType<Map>()
              .map(
                (item) => TeamItem.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList()
          : [],
    );
  }

  final int id;
  final String name;
  final String lastname;
  final String username;
  final String email;
  final String? bio;
  final String? avatarUrl;
  final List<CompetitionItem> preferredCompetitions;
  final List<TeamItem> preferredTeams;

  String get fullName => '$name $lastname'.trim();
}

class PublicProfile {
  PublicProfile({
    required this.id,
    required this.name,
    required this.lastname,
    required this.username,
    required this.bio,
    required this.avatarUrl,
    required this.validatedTipster,
    required this.followedByCurrentUser,
    required this.selfProfile,
    required this.followersCount,
    required this.followingCount,
    required this.preferredCompetitions,
    required this.preferredTeams,
  });

  factory PublicProfile.fromJson(Map<String, dynamic> json) {
    final rawCompetitions = json['preferredCompetitions'];
    final rawTeams = json['preferredTeams'];

    return PublicProfile(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      lastname: (json['lastname'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      bio: json['bio']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      validatedTipster: json['validatedTipster'] == true,
      followedByCurrentUser: json['followedByCurrentUser'] == true,
      selfProfile: json['selfProfile'] == true,
      followersCount: (json['followersCount'] as num?)?.toInt() ?? 0,
      followingCount: (json['followingCount'] as num?)?.toInt() ?? 0,
      preferredCompetitions: rawCompetitions is List
          ? rawCompetitions
              .whereType<Map>()
              .map(
                (item) => CompetitionItem.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList()
          : [],
      preferredTeams: rawTeams is List
          ? rawTeams
              .whereType<Map>()
              .map(
                (item) => TeamItem.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList()
          : [],
    );
  }

  final int id;
  final String name;
  final String lastname;
  final String username;
  final String? bio;
  final String? avatarUrl;
  final bool validatedTipster;
  final bool followedByCurrentUser;
  final bool selfProfile;
  final int followersCount;
  final int followingCount;
  final List<CompetitionItem> preferredCompetitions;
  final List<TeamItem> preferredTeams;

  String get fullName => '$name $lastname'.trim();

  PublicProfile copyWith({
    bool? followedByCurrentUser,
    int? followersCount,
  }) {
    return PublicProfile(
      id: id,
      name: name,
      lastname: lastname,
      username: username,
      bio: bio,
      avatarUrl: avatarUrl,
      validatedTipster: validatedTipster,
      followedByCurrentUser: followedByCurrentUser ?? this.followedByCurrentUser,
      selfProfile: selfProfile,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount,
      preferredCompetitions: preferredCompetitions,
      preferredTeams: preferredTeams,
    );
  }
}

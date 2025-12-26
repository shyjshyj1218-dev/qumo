class LeagueModel {
  final String id;
  final String tier; // bronze, silver, gold, sapphire, ruby, diamond, crystal
  final DateTime weekStartDate;
  final DateTime weekEndDate;
  final int seasonNumber;
  final DateTime createdAt;
  final DateTime updatedAt;

  LeagueModel({
    required this.id,
    required this.tier,
    required this.weekStartDate,
    required this.weekEndDate,
    this.seasonNumber = 1,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LeagueModel.fromSupabase(Map<String, dynamic> data) {
    DateTime parseWeekDate(String? dateStr, {required bool isStart}) {
      if (dateStr == null) return DateTime.now();
      final date = DateTime.parse(dateStr);
      // 시작일은 월요일 6시, 종료일은 일요일 22시
      if (isStart) {
        return DateTime(date.year, date.month, date.day, 6, 0);
      } else {
        return DateTime(date.year, date.month, date.day, 22, 0);
      }
    }

    return LeagueModel(
      id: data['id'] ?? '',
      tier: data['tier'] ?? 'bronze',
      weekStartDate: parseWeekDate(data['week_start_date'], isStart: true),
      weekEndDate: parseWeekDate(data['week_end_date'], isStart: false),
      seasonNumber: data['season_number'] ?? 1,
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'])
          : DateTime.now(),
      updatedAt: data['updated_at'] != null
          ? DateTime.parse(data['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'tier': tier,
      'week_start_date': weekStartDate.toIso8601String().split('T')[0],
      'week_end_date': weekEndDate.toIso8601String().split('T')[0],
      'season_number': seasonNumber,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // 티어 한글 이름
  String get tierName {
    switch (tier) {
      case 'bronze':
        return '브론즈';
      case 'silver':
        return '실버';
      case 'gold':
        return '골드';
      case 'sapphire':
        return '사이파어';
      case 'ruby':
        return '루비';
      case 'diamond':
        return '다이아';
      case 'crystal':
        return '크리스탈';
      default:
        return '브론즈';
    }
  }

  // 티어 색상 (향후 사용)
  String get tierColor {
    switch (tier) {
      case 'bronze':
        return '#CD7F32';
      case 'silver':
        return '#C0C0C0';
      case 'gold':
        return '#FFD700';
      case 'sapphire':
        return '#0F52BA';
      case 'ruby':
        return '#E0115F';
      case 'diamond':
        return '#B9F2FF';
      case 'crystal':
        return '#A7D8DE';
      default:
        return '#CD7F32';
    }
  }
}

class LeagueRankingModel {
  final String id;
  final String userId;
  final String leagueId;
  final int ratingAtStart;
  final int? ratingAtEnd;
  final int leagueScore;
  final int? rank;
  final bool promoted;
  final bool demoted;
  final DateTime createdAt;
  final DateTime updatedAt;

  LeagueRankingModel({
    required this.id,
    required this.userId,
    required this.leagueId,
    required this.ratingAtStart,
    this.ratingAtEnd,
    this.leagueScore = 0,
    this.rank,
    this.promoted = false,
    this.demoted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LeagueRankingModel.fromSupabase(Map<String, dynamic> data) {
    return LeagueRankingModel(
      id: data['id'] ?? '',
      userId: data['user_id'] ?? '',
      leagueId: data['league_id'] ?? '',
      ratingAtStart: data['rating_at_start'] ?? 0,
      ratingAtEnd: data['rating_at_end'],
      leagueScore: data['league_score'] ?? 0,
      rank: data['rank'],
      promoted: data['promoted'] ?? false,
      demoted: data['demoted'] ?? false,
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'])
          : DateTime.now(),
      updatedAt: data['updated_at'] != null
          ? DateTime.parse(data['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'user_id': userId,
      'league_id': leagueId,
      'rating_at_start': ratingAtStart,
      'rating_at_end': ratingAtEnd,
      'league_score': leagueScore,
      'rank': rank,
      'promoted': promoted,
      'demoted': demoted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

// 리그 티어 상수
class LeagueTier {
  static const String bronze = 'bronze';
  static const String silver = 'silver';
  static const String gold = 'gold';
  static const String sapphire = 'sapphire';
  static const String ruby = 'ruby';
  static const String diamond = 'diamond';
  static const String crystal = 'crystal';

  static const List<String> allTiers = [
    bronze,
    silver,
    gold,
    sapphire,
    ruby,
    diamond,
    crystal,
  ];

  // 티어 순서 (낮은 순서부터)
  static int getTierOrder(String tier) {
    return allTiers.indexOf(tier);
  }

  // 다음 티어
  static String? getNextTier(String tier) {
    final index = allTiers.indexOf(tier);
    if (index >= 0 && index < allTiers.length - 1) {
      return allTiers[index + 1];
    }
    return null; // 최고 티어
  }

  // 이전 티어
  static String? getPreviousTier(String tier) {
    final index = allTiers.indexOf(tier);
    if (index > 0) {
      return allTiers[index - 1];
    }
    return null; // 최하위 티어
  }
}

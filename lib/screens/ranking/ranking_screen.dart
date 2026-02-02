import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/colors.dart';
import '../../models/user.dart';
import '../../utils/constants.dart';
import '../../services/supabase_service.dart';
import '../../providers/auth_provider.dart';

class RankingScreen extends ConsumerStatefulWidget {
  const RankingScreen({super.key});

  @override
  ConsumerState<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends ConsumerState<RankingScreen> {
  String _selectedFilter = '전체'; // 전체, 리그, 친구

  @override
  Widget build(BuildContext context) {
    final supabase = SupabaseService.client;
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 헤더
            _buildTopHeader(context, currentUser),
            // 그래픽 및 제목
            _buildHeaderGraphic(),
            // 필터 탭
            _buildFilterTabs(),
            // 랭킹 헤더
            _buildRankingHeader(),
            // 랭킹 리스트
            Expanded(
              child: FutureBuilder<List<UserModel>>(
                future: _fetchRankings(supabase),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        '오류: ${snapshot.error}',
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text(
                        '랭킹 데이터가 없습니다',
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                    );
                  }

                  final users = snapshot.data!;

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final rank = index + 1;
                      return _buildRankingCard(user, rank);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context, currentUser) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // 뒤로가기
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          // 앱 이름
          const Expanded(
            child: Center(
              child: Text(
                'QUMO',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          // 프로필 아이콘
          GestureDetector(
            onTap: () {
              // 프로필 화면으로 이동
            },
            child: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primary,
              backgroundImage: currentUser?.userMetadata?['avatar_url'] != null
                  ? NetworkImage(currentUser!.userMetadata!['avatar_url'])
                  : null,
              child: currentUser?.userMetadata?['avatar_url'] == null
                  ? const Icon(Icons.person, color: AppColors.textWhite)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderGraphic() {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 그래픽 배경 (두 동물 머리 효과)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 왼쪽 동물 (오렌지/갈색)
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.coin, AppColors.primary],
                  ),
                ),
              ),
              // 중앙 엠블럼
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.star,
                  color: AppColors.textWhite,
                  size: 40,
                ),
              ),
              // 오른쪽 동물 (갈색/베이지)
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.background,
                    ],
                  ),
                ),
              ),
            ],
          ),
          // 제목
          Positioned(
            bottom: 20,
            child: const Text(
              'The 20 Greatest',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterTab('전체', 0),
          const SizedBox(width: 12),
          _buildFilterTab('리그', 1),
          const SizedBox(width: 12),
          _buildFilterTab('친구', 2),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, int index) {
    final isSelected = _selectedFilter == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedFilter = label);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.rankingSelectedTab
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected
                  ? AppColors.textWhite
                  : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRankingHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(
              'POS.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'PLAYER',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Row(
            children: [
              Text(
                'SCORE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.sort,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRankingCard(UserModel user, int rank) {
    final isFirst = rank == 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.rankingCard,
        borderRadius: BorderRadius.circular(12),
        border: isFirst
            ? Border.all(
                color: AppColors.primary,
                width: 2,
              )
            : null,
      ),
      child: Row(
        children: [
          // 순위
          SizedBox(
            width: 50,
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isFirst
                    ? AppColors.primary
                    : AppColors.textPrimary,
              ),
            ),
          ),
          // 플레이어 정보
          Expanded(
            child: Row(
              children: [
                // 아바타
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primary,
                      backgroundImage: user.profileImage != null
                          ? NetworkImage(user.profileImage!)
                          : null,
                      child: user.profileImage == null
                          ? Text(
                              user.nickname.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.textWhite,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    // 팀 배지 (아바타 왼쪽 하단)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppColors.difficultyBeginner,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.rankingCard,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.star,
                          size: 10,
                          color: AppColors.textWhite,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                // 이름 및 팀
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.nickname,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Team', // 팀 정보 (향후 추가)
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 점수
          Text(
            '${user.rating}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Future<List<UserModel>> _fetchRankings(dynamic supabase) async {
    final response = await supabase
        .from(AppConstants.usersCollection)
        .select()
        .order('rating', ascending: false)
        .limit(20);

    return (response as List)
        .map((data) => UserModel.fromSupabase(data as Map<String, dynamic>))
        .toList();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/colors.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../utils/constants.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _friends = [];
  List<UserModel> _searchResults = [];
  bool _isLoading = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) return;

      final supabase = SupabaseService.client;
      
      // 친구 목록 조회 (양방향 친구 관계)
      final response = await supabase
          .from('friends')
          .select('''
            friend_id,
            users!friends_friend_id_fkey (
              id,
              email,
              nickname,
              coins,
              tickets,
              rating,
              profile_image,
              created_at,
              updated_at
            )
          ''')
          .eq('user_id', currentUser.id)
          .eq('status', 'accepted');

      final friendsList = (response as List)
          .map((item) {
            final friendData = item['users'];
            if (friendData != null) {
              return UserModel.fromSupabase(friendData as Map<String, dynamic>);
            }
            return null;
          })
          .whereType<UserModel>()
          .toList();
      setState(() {
        _friends = friendsList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('친구 목록을 불러오는 중 오류가 발생했습니다: $e'),
            backgroundColor: AppColors.difficultyExpert,
          ),
        );
      }
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) return;

      final supabase = SupabaseService.client;
      
      // 닉네임 또는 ID로 검색 (자신 제외)
      // ID 검색을 위해 UUID 형식인지 확인
      final isUuid = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false).hasMatch(query);
      
      var queryBuilder = supabase
          .from(AppConstants.usersCollection)
          .select()
          .neq('id', currentUser.id);
      
      if (isUuid) {
        // ID로 검색
        queryBuilder = queryBuilder.eq('id', query);
      } else {
        // 닉네임으로 검색
        queryBuilder = queryBuilder.ilike('nickname', '%$query%');
      }
      
      final response = await queryBuilder.limit(20);

      final usersList = (response as List)
          .map((data) => UserModel.fromSupabase(data as Map<String, dynamic>))
          .toList();
      setState(() {
        _searchResults = usersList;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('검색 중 오류가 발생했습니다: $e'),
            backgroundColor: AppColors.difficultyExpert,
          ),
        );
      }
    }
  }

  Future<void> _addFriend(String friendId) async {
    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) return;

      final supabase = SupabaseService.client;
      
      // 친구 요청 전송
      await supabase.from('friends').insert({
        'user_id': currentUser.id,
        'friend_id': friendId,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('친구 요청을 보냈습니다'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('친구 추가 중 오류가 발생했습니다: $e'),
            backgroundColor: AppColors.difficultyExpert,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          '친구',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // 검색창
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '닉네임 또는 ID로 검색',
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          _searchUsers('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.backgroundWhite,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.borderGray),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.borderGray),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                _searchUsers(value);
              },
            ),
          ),
          // 친구 목록 또는 검색 결과
          Expanded(
            child: _isSearching
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  )
                : _searchController.text.isNotEmpty
                    ? _buildSearchResults()
                    : _buildFriendsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    if (_friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              '친구가 없습니다',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '검색창에서 친구를 찾아 추가해보세요',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _friends.length,
      itemBuilder: (context, index) {
        final friend = _friends[index];
        return _buildFriendCard(friend, isFriend: true);
      },
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return Center(
        child: Text(
          '검색 결과가 없습니다',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        final isAlreadyFriend = _friends.any((f) => f.id == user.id);
        return _buildFriendCard(user, isFriend: isAlreadyFriend);
      },
    );
  }

  Widget _buildFriendCard(UserModel user, {required bool isFriend}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 프로필 이미지
          CircleAvatar(
            radius: 28,
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
                      fontSize: 18,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          // 사용자 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.nickname,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '레이팅: ${user.rating}',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // 친구 추가 버튼 또는 친구 표시
          if (isFriend)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '친구',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            )
          else
            ElevatedButton(
              onPressed: () => _addFriend(user.id),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textWhite,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                '추가',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}


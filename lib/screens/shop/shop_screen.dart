import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/colors.dart';
import '../../utils/constants.dart';
import '../../services/supabase_service.dart';
import '../../services/shop_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';

class ShopItem {
  final String id;
  final String name;
  final String description;
  final int? priceCoins;
  final int? priceTickets;
  final String? imageUrl;

  ShopItem({
    required this.id,
    required this.name,
    required this.description,
    this.priceCoins,
    this.priceTickets,
    this.imageUrl,
  });

  factory ShopItem.fromSupabase(Map<String, dynamic> data) {
    return ShopItem(
      id: data['id']?.toString() ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      priceCoins: data['price_coins'],
      priceTickets: data['price_tickets'],
      imageUrl: data['image_url'],
    );
  }
}

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  final shopService = ShopService();

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final userProfile = ref.watch(userProfileProvider);
    final supabase = SupabaseService.client;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('상점'),
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        actions: [
          // 골드 및 티켓 표시
          if (userProfile.value != null) ...[
            _buildCurrencyBadge(
              icon: Icons.monetization_on,
              value: userProfile.value!.coins,
              color: AppColors.coin,
            ),
            const SizedBox(width: 8),
            _buildCurrencyBadge(
              icon: Icons.confirmation_number,
              value: userProfile.value!.tickets,
              color: AppColors.ticket,
            ),
            const SizedBox(width: 16),
          ],
        ],
      ),
      body: Column(
        children: [
          // 골드/티켓 구매 섹션
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderGray),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '골드/티켓 구매',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildPurchaseCard(
                        title: '골드 100',
                        price: '₩1,000',
                        icon: Icons.monetization_on,
                        color: AppColors.coin,
                        onTap: () => _purchaseGold(100, 1000),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPurchaseCard(
                        title: '골드 500',
                        price: '₩4,500',
                        icon: Icons.monetization_on,
                        color: AppColors.coin,
                        onTap: () => _purchaseGold(500, 4500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildPurchaseCard(
                        title: '티켓 10',
                        price: '₩2,000',
                        icon: Icons.confirmation_number,
                        color: AppColors.ticket,
                        onTap: () => _purchaseTickets(10, 2000),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPurchaseCard(
                        title: '티켓 50',
                        price: '₩9,000',
                        icon: Icons.confirmation_number,
                        color: AppColors.ticket,
                        onTap: () => _purchaseTickets(50, 9000),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 상점 아이템 목록
          Expanded(
            child: FutureBuilder<List<ShopItem>>(
        future: _fetchShopItems(supabase),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('오류: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('상점 아이템이 없습니다'));
          }

          final items = snapshot.data!;

          return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
                    return _buildShopItemCard(item, currentUser?.id);
            },
          );
        },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyBadge({
    required IconData icon,
    required int value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 4),
          Text(
            value.toString(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseCard({
    required String title,
    required String price,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              price,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _purchaseGold(int coins, int price) async {
    // TODO: 실제 결제 연동
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    // 임시: 바로 지급 (실제로는 결제 검증 후)
    final success = await shopService.purchaseWithInApp(
      currentUser.id,
      'gold_$coins',
      coins,
      0,
    );

    if (success && mounted) {
      ref.invalidate(userProfileProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('골드 $coins개가 지급되었습니다.'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  Future<void> _purchaseTickets(int tickets, int price) async {
    // TODO: 실제 결제 연동
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    // 임시: 바로 지급 (실제로는 결제 검증 후)
    final success = await shopService.purchaseWithInApp(
      currentUser.id,
      'tickets_$tickets',
      0,
      tickets,
    );

    if (success && mounted) {
      ref.invalidate(userProfileProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('티켓 $tickets개가 지급되었습니다.'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  Future<List<ShopItem>> _fetchShopItems(supabase) async {
    final response = await supabase
        .from(AppConstants.shopItemsCollection)
        .select();

    return (response as List)
        .map((data) => ShopItem.fromSupabase(data as Map<String, dynamic>))
        .toList();
  }

  Widget _buildShopItemCard(ShopItem item, String? userId) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이미지
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.lightGray,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: item.imageUrl != null
                  ? Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                    )
                  : const Icon(
                      Icons.shopping_bag,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
            ),
          ),
          // 정보
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // 가격
                Row(
                  children: [
                    if (item.priceCoins != null) ...[
                      Icon(Icons.monetization_on,
                          size: 16, color: AppColors.coin),
                      const SizedBox(width: 4),
                      Text(
                        '${item.priceCoins}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.coin,
                        ),
                      ),
                    ],
                    if (item.priceTickets != null) ...[
                      if (item.priceCoins != null) const SizedBox(width: 8),
                      Icon(Icons.confirmation_number,
                          size: 16, color: AppColors.ticket),
                      const SizedBox(width: 4),
                      Text(
                        '${item.priceTickets}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ticket,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                // 구매 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: userId == null
                        ? null
                        : () async {
                            final useCoins = item.priceCoins != null;
                            final success = await shopService.purchaseItem(
                              userId,
                              item.id,
                              useCoins: useCoins,
                            );

                            if (success && mounted) {
                              ref.invalidate(userProfileProvider);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('구매가 완료되었습니다.'),
                                  backgroundColor: AppColors.primary,
                                ),
                              );
                            } else if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('구매에 실패했습니다. 재화가 부족할 수 있습니다.'),
                                  backgroundColor: AppColors.difficultyExpert,
                                ),
                              );
                            }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textWhite,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('구매'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

class ShopService {
  final supabase = SupabaseService.client;

  // 상점 아이템 구매 (코인/티켓으로)
  Future<bool> purchaseItem(String userId, String itemId, {bool useCoins = true}) async {
    try {
      // 아이템 정보 가져오기
      final item = await supabase
          .from('shop_items')
          .select()
          .eq('id', itemId)
          .single();

      final user = await supabase
          .from('users')
          .select('coins, tickets')
          .eq('id', userId)
          .single();

      final currentCoins = (user['coins'] ?? 0) as int;
      final currentTickets = (user['tickets'] ?? 0) as int;

      int price = 0;

      if (useCoins) {
        price = item['price_coins'] as int? ?? 0;
        if (price == 0 || currentCoins < price) {
          return false; // 코인 부족
        }
      } else {
        price = item['price_tickets'] as int? ?? 0;
        if (price == 0 || currentTickets < price) {
          return false; // 티켓 부족
        }
      }

      // 구매 처리
      if (useCoins) {
        await supabase
            .from('users')
            .update({
              'coins': currentCoins - price,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', userId);
      } else {
        await supabase
            .from('users')
            .update({
              'tickets': currentTickets - price,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', userId);
      }

      // 구매 기록 저장 (향후 인벤토리 시스템에 사용)
      // TODO: user_purchases 테이블 생성 및 기록

      return true;
    } catch (e) {
      debugPrint('아이템 구매 오류: $e');
      return false;
    }
  }

  // 인앱 결제로 골드/티켓 구매
  Future<bool> purchaseWithInApp(String userId, String productId, int coins, int tickets) async {
    try {
      // 인앱 결제 검증은 클라이언트에서 처리 후 서버로 전달
      // 여기서는 결제 검증 후 골드/티켓 지급만 처리

      final user = await supabase
          .from('users')
          .select('coins, tickets')
          .eq('id', userId)
          .single();

      final currentCoins = (user['coins'] ?? 0) as int;
      final currentTickets = (user['tickets'] ?? 0) as int;

      await supabase
          .from('users')
          .update({
            'coins': currentCoins + coins,
            'tickets': currentTickets + tickets,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      // 결제 기록 저장 (향후)
      // TODO: payments 테이블 생성 및 기록

      return true;
    } catch (e) {
      debugPrint('인앱 결제 처리 오류: $e');
      return false;
    }
  }
}

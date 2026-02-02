import 'package:go_router/go_router.dart';
import '../screens/auth/auth_screen.dart';
import '../screens/auth/email_login_screen.dart';
import '../screens/auth/google_login_screen.dart';
import '../screens/auth/naver_login_screen.dart';
import '../screens/auth/nickname_setup_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/quiz/difficulty_selection_screen.dart';
import '../screens/quiz/quiz_room_screen.dart';
import '../screens/quiz/challenge_quiz_screen.dart';
import '../screens/matching/matching_screen.dart';
import '../screens/matching/realtime_match_game_screen.dart';
import '../screens/matching/simple_match_game_screen.dart';
import '../screens/matching/match_result_screen.dart';
import '../screens/mission/mission_screen.dart';
import '../screens/ranking/ranking_screen.dart';
import '../screens/shop/shop_screen.dart';
import '../screens/friends/friends_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../models/match_user.dart';
import '../models/quiz_question.dart';
import '../widgets/common/main_layout.dart';

final router = GoRouter(
  initialLocation: '/auth',
  routes: [
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthScreen(),
    ),
    GoRoute(
      path: '/email-login',
      builder: (context, state) => const EmailLoginScreen(),
    ),
    GoRoute(
      path: '/google-login',
      builder: (context, state) => const GoogleLoginScreen(),
    ),
    GoRoute(
      path: '/naver-login',
      builder: (context, state) => const NaverLoginScreen(),
    ),
    GoRoute(
      path: '/nickname-setup',
      builder: (context, state) {
        final userId = state.extra as String?;
        return NicknameSetupScreen(userId: userId);
      },
    ),
    // 메인 탭 화면들을 ShellRoute로 감싸기 (하단바가 있는 화면들)
    ShellRoute(
      builder: (context, state, child) {
        return MainLayout(
          currentPath: state.uri.path,
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/mission',
          builder: (context, state) => const MissionScreen(),
        ),
        GoRoute(
          path: '/challenge-quiz',
          builder: (context, state) => const ChallengeQuizScreen(),
        ),
        GoRoute(
          path: '/ranking',
          builder: (context, state) => const RankingScreen(),
        ),
        GoRoute(
          path: '/shop',
          builder: (context, state) => const ShopScreen(),
        ),
      ],
    ),
    // 하단바가 필요 없는 화면들
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/difficulty-selection',
      builder: (context, state) => const DifficultySelectionScreen(),
    ),
    GoRoute(
      path: '/quiz-room',
      builder: (context, state) {
        final difficulty = state.uri.queryParameters['difficulty'] ?? 'beginner';
        return QuizRoomScreen(difficulty: difficulty);
      },
    ),
    GoRoute(
      path: '/matching',
      builder: (context, state) => const MatchingScreen(),
    ),
    GoRoute(
      path: '/realtime-match-game',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>?;
        
        // 새로운 단순 문제 화면 (1개 문제)
        if (data?['roomId'] != null && data?['question'] != null) {
          return SimpleMatchGameScreen(
            roomId: data!['roomId'] as String,
            question: data['question'] as QuizQuestion,
          );
        }
        
        // 기존 화면 (여러 문제)
        return RealtimeMatchGameScreen(
          opponent: data?['opponent'] as MatchUser?,
          matchId: data?['matchId'] as String?,
          questions: data?['questions'] as List<QuizQuestion>?,
        );
      },
    ),
    GoRoute(
      path: '/match-result',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>?;
        return MatchResultScreen(
          result: data?['result'] as Map<String, dynamic>,
          opponent: data?['opponent'] as MatchUser,
          playerCorrectCount: (data?['playerCorrectCount'] as int?) ?? 0,
          opponentCorrectCount: (data?['opponentCorrectCount'] as int?) ?? 0,
        );
      },
    ),
    GoRoute(
      path: '/friends',
      builder: (context, state) => const FriendsScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);


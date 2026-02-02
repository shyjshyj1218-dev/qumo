import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/colors.dart';
import 'bottom_navigation.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  final String currentPath;

  const MainLayout({
    super.key,
    required this.child,
    required this.currentPath,
  });

  @override
  Widget build(BuildContext context) {
    // 현재 경로에 따라 탭 인덱스 결정
    int currentIndex = 0;
    if (currentPath == '/home') {
      currentIndex = 0;
    } else if (currentPath == '/mission') {
      currentIndex = 1;
    } else if (currentPath == '/challenge-quiz') {
      currentIndex = 2;
    } else if (currentPath == '/ranking') {
      currentIndex = 3;
    } else if (currentPath == '/shop') {
      currentIndex = 4;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      bottomNavigationBar: BottomNavigation(
        currentIndex: currentIndex,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/mission');
              break;
            case 2:
              context.go('/challenge-quiz');
              break;
            case 3:
              context.go('/ranking');
              break;
            case 4:
              context.go('/shop');
              break;
          }
        },
      ),
    );
  }
}


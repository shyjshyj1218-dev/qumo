// 기본 Flutter 위젯 테스트.
// 앱이 정상적으로 빌드되는지 스모크 테스트합니다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:qumo/app.dart';

void main() {
  testWidgets('App 스모크 테스트', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: App(),
      ),
    );
    // 앱이 빌드되어 프레임이 렌더링되는지 확인
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

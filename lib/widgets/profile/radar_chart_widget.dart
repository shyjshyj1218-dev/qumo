import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../config/colors.dart';

class RadarChartWidget extends StatelessWidget {
  final Map<String, double> stats; // 능력치 맵 (예: {'속도': 80, '정확도': 90, ...})
  final double size;
  final Color fillColor;
  final Color strokeColor;
  final double strokeWidth;

  const RadarChartWidget({
    super.key,
    required this.stats,
    this.size = 200,
    this.fillColor = AppColors.primary,
    this.strokeColor = AppColors.textPrimary,
    this.strokeWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: RadarChartPainter(
        stats: stats,
        fillColor: fillColor,
        strokeColor: strokeColor,
        strokeWidth: strokeWidth,
      ),
    );
  }
}

class RadarChartPainter extends CustomPainter {
  final Map<String, double> stats;
  final Color fillColor;
  final Color strokeColor;
  final double strokeWidth;

  RadarChartPainter({
    required this.stats,
    required this.fillColor,
    required this.strokeColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 50; // 라벨 공간 확보 (8각형이므로 더 넓게)

    final statKeys = stats.keys.toList();
    final statCount = statKeys.length;
    
    if (statCount < 3) return; // 최소 3개 이상 필요
    if (statCount != 8) {
      // 8개가 아니면 경고 (디버그용)
      print('Warning: Radar chart expects 8 categories, got $statCount');
    }

    final angleStep = 2 * math.pi / statCount;

    // 배경 그리드 (5단계)
    final gridPaint = Paint()
      ..color = AppColors.borderGray.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 1; i <= 5; i++) {
      final gridRadius = radius * (i / 5);
      final path = Path();
      for (int j = 0; j < statCount; j++) {
        final angle = -math.pi / 2 + (j * angleStep); // 상단부터 시작
        final x = center.dx + gridRadius * math.cos(angle);
        final y = center.dy + gridRadius * math.sin(angle);
        if (j == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // 축선 그리기
    final axisPaint = Paint()
      ..color = AppColors.borderGray.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 0; i < statCount; i++) {
      final angle = -math.pi / 2 + (i * angleStep);
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      canvas.drawLine(center, Offset(x, y), axisPaint);
    }

    // 능력치 영역 그리기
    final dataPath = Path();
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < statCount; i++) {
      final statName = statKeys[i];
      final statValue = stats[statName] ?? 0.0;
      final normalizedValue = (statValue / 100).clamp(0.0, 1.0); // 0-100을 0-1로 정규화
      
      final angle = -math.pi / 2 + (i * angleStep);
      final distance = radius * normalizedValue;
      final x = center.dx + distance * math.cos(angle);
      final y = center.dy + distance * math.sin(angle);

      if (i == 0) {
        dataPath.moveTo(x, y);
      } else {
        dataPath.lineTo(x, y);
      }

      // 라벨 그리기 (능력치 이름) - 8각형이므로 더 넓게
      final labelDistance = radius + 30;
      final labelX = center.dx + labelDistance * math.cos(angle);
      final labelY = center.dy + labelDistance * math.sin(angle);

      textPainter.text = TextSpan(
        text: statName,
        style: TextStyle(
          fontSize: 12,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      );
      textPainter.layout();

      // 텍스트 위치 조정 (중앙 정렬)
      final textOffset = Offset(
        labelX - textPainter.width / 2,
        labelY - textPainter.height / 2,
      );
      textPainter.paint(canvas, textOffset);

      // 값 표시 (선택적)
      if (normalizedValue > 0.1) {
        final valueTextPainter = TextPainter(
          text: TextSpan(
            text: '${statValue.toInt()}',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        );
        valueTextPainter.layout();

        final valueDistance = radius * normalizedValue * 0.7;
        final valueX = center.dx + valueDistance * math.cos(angle);
        final valueY = center.dy + valueDistance * math.sin(angle);

        valueTextPainter.paint(
          canvas,
          Offset(
            valueX - valueTextPainter.width / 2,
            valueY - valueTextPainter.height / 2,
          ),
        );
      }
    }

    dataPath.close();

    // 능력치 영역 채우기
    final fillPaint = Paint()
      ..color = fillColor.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    canvas.drawPath(dataPath, fillPaint);

    // 능력치 영역 테두리
    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawPath(dataPath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

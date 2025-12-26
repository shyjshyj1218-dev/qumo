import 'package:flutter/material.dart';


class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: onPressed == null || isLoading
                  ? const Color(0xFF1F1F1F).withOpacity(0.12)
                  : const Color(0xFF747775),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(4),
            boxShadow: onPressed != null && !isLoading
                ? [
                    BoxShadow(
                      color: const Color(0xFF3C4043).withOpacity(0.30),
                      blurRadius: 1,
                      offset: const Offset(0, 1),
                    ),
                    BoxShadow(
                      color: const Color(0xFF3C4043).withOpacity(0.15),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Google 로고 SVG
              SizedBox(
                width: 20,
                height: 20,
                child: CustomPaint(
                  painter: GoogleLogoPainter(
                    opacity: (onPressed == null || isLoading) ? 0.38 : 1.0,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 텍스트
              Text(
                'Google로 로그인',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.25,
                  color: (onPressed == null || isLoading)
                      ? const Color(0xFF1F1F1F).withOpacity(0.38)
                      : const Color(0xFF1F1F1F),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GoogleLogoPainter extends CustomPainter {
  final double opacity;

  GoogleLogoPainter({this.opacity = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    // SVG viewBox는 0 0 48 48이므로 스케일링 필요
    final scale = size.width / 48.0;
    canvas.save();
    canvas.scale(scale);

    final paint = Paint()..style = PaintingStyle.fill;

    // Red (#EA4335) - 왼쪽 위
    // M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z
    paint.color = const Color(0xFFEA4335).withOpacity(opacity);
    final redPath = Path()
      ..moveTo(24, 9.5)
      ..cubicTo(27.54, 9.5, 30.71, 10.72, 33.21, 13.1)
      ..lineTo(40.06, 6.25)
      ..cubicTo(35.9, 2.38, 30.47, 0, 24, 0)
      ..cubicTo(14.62, 0, 6.51, 5.38, 2.56, 13.22)
      ..lineTo(10.54, 19.41)
      ..cubicTo(12.43, 13.72, 17.74, 9.5, 24, 9.5)
      ..close();
    canvas.drawPath(redPath, paint);

    // Blue (#4285F4) - 오른쪽 위
    // M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z
    paint.color = const Color(0xFF4285F4).withOpacity(opacity);
    final bluePath = Path()
      ..moveTo(46.98, 24.55)
      ..cubicTo(46.98, 22.98, 46.83, 21.46, 46.6, 20)
      ..lineTo(24, 20)
      ..lineTo(24, 29.02)
      ..lineTo(36.94, 29.02)
      ..cubicTo(36.36, 31.98, 34.68, 34.5, 32.16, 36.2)
      ..lineTo(39.89, 42.2)
      ..cubicTo(44.4, 38.02, 46.98, 31.91, 46.98, 24.55)
      ..close();
    canvas.drawPath(bluePath, paint);

    // Yellow (#FBBC05) - 왼쪽 아래
    // M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z
    paint.color = const Color(0xFFFBBC05).withOpacity(opacity);
    final yellowPath = Path()
      ..moveTo(10.53, 28.59)
      ..cubicTo(10.05, 27.14, 9.77, 25.6, 9.77, 24)
      ..cubicTo(9.77, 22.4, 10.05, 20.86, 10.53, 19.41)
      ..lineTo(2.55, 13.22)
      ..cubicTo(0.92, 16.46, 0, 20.12, 0, 24)
      ..cubicTo(0, 27.88, 0.92, 31.54, 2.56, 34.78)
      ..lineTo(10.53, 28.59)
      ..close();
    canvas.drawPath(yellowPath, paint);

    // Green (#34A853) - 오른쪽 아래
    // M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z
    paint.color = const Color(0xFF34A853).withOpacity(opacity);
    final greenPath = Path()
      ..moveTo(24, 48)
      ..cubicTo(30.48, 48, 35.93, 45.87, 39.89, 42.19)
      ..lineTo(32.16, 36.19)
      ..cubicTo(30.01, 37.64, 27.28, 38.49, 24.04, 38.49)
      ..cubicTo(17.78, 38.49, 12.47, 34.27, 10.57, 28.58)
      ..lineTo(2.59, 34.77)
      ..cubicTo(6.51, 42.62, 14.62, 48, 24, 48)
      ..close();
    canvas.drawPath(greenPath, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(GoogleLogoPainter oldDelegate) {
    return oldDelegate.opacity != opacity;
  }
}


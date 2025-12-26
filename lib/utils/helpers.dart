import 'package:intl/intl.dart';

class Helpers {
  static String formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  static String formatDate(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }

  static String getDifficultyLabel(String difficulty) {
    switch (difficulty) {
      case 'beginner':
        return '초급';
      case 'intermediate':
        return '중급';
      case 'advanced':
        return '상급';
      case 'expert':
        return '최상급';
      default:
        return difficulty;
    }
  }

  static String getResultLabel(String result) {
    switch (result) {
      case 'win':
        return '승리';
      case 'lose':
        return '패배';
      case 'draw':
        return '무승부';
      default:
        return result;
    }
  }
}


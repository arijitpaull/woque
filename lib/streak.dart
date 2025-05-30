import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:woke/question_hive.dart';
import 'package:woke/rewards_hive.dart';


Future<int> getCurrentStreak() async {
  final streakInfo = await getCurrentStreakInfo();
  return streakInfo['streak'];
}


Future<Map<String, dynamic>> getCurrentStreakInfo() async {
  final now = DateTime.now();
  DateTime currentDate = DateTime(now.year, now.month, now.day);
  
  int streak = 0;
  bool isInGracePeriod = false;
  bool needsTodayEntry = false;
  
  
  final todayAnswer = await getAnswerForDate(currentDate);
  if (todayAnswer != null && todayAnswer.isNotEmpty) {
    
    streak = 1;
    needsTodayEntry = false;
  } else {
    
    final yesterday = currentDate.subtract(const Duration(days: 1));
    final yesterdayAnswer = await getAnswerForDate(yesterday);
    
    if (yesterdayAnswer != null && yesterdayAnswer.isNotEmpty) {
      
      isInGracePeriod = true;
      needsTodayEntry = true;
      
      
      bool streakContinues = true;
      int daysToCheck = 1; 
      
      while (streakContinues && daysToCheck < 730) { 
        final checkDate = currentDate.subtract(Duration(days: daysToCheck));
        final answer = await getAnswerForDate(checkDate);
        
        if (answer != null && answer.isNotEmpty) {
          streak++;
          daysToCheck++;
        } else {
          streakContinues = false;
        }
      }
    } else {
      
      streak = 0;
      needsTodayEntry = false;
    }
  }

  
  
  if (!isInGracePeriod && streak > 0) {
    bool streakContinues = true;
    int daysToCheck = 1;
    
    while (streakContinues && daysToCheck < 730) {
      final checkDate = currentDate.subtract(Duration(days: daysToCheck));
      final answer = await getAnswerForDate(checkDate);
      
      if (answer != null && answer.isNotEmpty) {
        streak++;
        daysToCheck++;
      } else {
        streakContinues = false;
      }
    }
  }

  
  if (streak > 0) {
    checkAndUnlockReward(streak).then((_) {
      
    });
  }

  return {
    'streak': streak,
    'isInGracePeriod': isInGracePeriod,
    'needsTodayEntry': needsTodayEntry
  };
}


Future<String?> getAnswerForDate(DateTime date) async {
  final questionKey = _getQuestionKey(date);
  
  final answersBox = Hive.box('questionAnswers');
  final answers = answersBox.get(questionKey) ?? [];
  
  
  for (var answer in answers) {
    try {
      
      final answerMap = answer is Map ? Map<String, dynamic>.from(answer) : null;
      if (answerMap != null) {
        final qa = QuestionAnswer.fromJson(answerMap);
        if (qa.dateAnswered.year == date.year && 
            qa.dateAnswered.month == date.month && 
            qa.dateAnswered.day == date.day) {
          return qa.answer;
        }
      }
    } catch (e) {
      debugPrint('Error parsing answer: $e');
      continue;
    }
  }
  
  return null;
}


String _getQuestionKey(DateTime date) {
  final dayOfYear = _getDayOfYear(date);
  if (_isLeapDay(date)) {
    return 'leapDay';
  }
  return 'day_$dayOfYear';
}


int _getDayOfYear(DateTime date) {
  final firstDayOfYear = DateTime(date.year, 1, 1);
  final difference = date.difference(firstDayOfYear).inDays + 1;
  return difference;
}


bool _isLeapDay(DateTime date) {
  return date.month == 2 && date.day == 29;
}
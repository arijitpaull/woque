import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:woke/ai_service.dart';
import 'package:woke/answer_compare.dart';
import 'package:woke/notification_service.dart';
import 'package:woke/question_hive.dart';
import 'package:intl/intl.dart';
import 'package:woke/badge_celebration.dart';
import 'package:woke/rewards_hive.dart'; 

class QuestionsPage extends StatefulWidget {
  const QuestionsPage({super.key});

  @override
  State<QuestionsPage> createState() => _QuestionsPageState();
}

class _QuestionsPageState extends State<QuestionsPage> {
  final TextEditingController _answerController = TextEditingController();
  String _currentQuestion = '';
  String? _currentAnswer;
  bool _isEditing = false;
  bool _isLoading = true;
  List<QuestionAnswer> _previousAnswers = [];
  bool _showPreviousAnswers = false;
  String? _errorMessage;
  int _currentStreak = 0; 
  bool _isSubmitting = false;
  bool _isInGracePeriod = false; 

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      
      _currentQuestion = "What emotion did you feel the most today, and why?";
      
      try {
        final question = await getTodaysQuestion();
        setState(() {
          _currentQuestion = question;
        });
        print("Successfully loaded question: $_currentQuestion");
      } catch (e) {
        print("Error loading question: $e");
        setState(() {
          _errorMessage = "Could not load today's question: $e";
        });
      }

      try {
        _currentAnswer = await getAnswerForToday();
        print("Loaded answer: $_currentAnswer");
      } catch (e) {
        print("Error loading today's answer: $e");
        setState(() {
          _errorMessage = (_errorMessage ?? "") + "\nCould not load today's answer: $e";
        });
      }

      try {
        _previousAnswers = await getPreviousAnswers();
        print("Loaded ${_previousAnswers.length} previous answers");
      } catch (e) {
        print("Error loading previous answers: $e");
        setState(() {
          _errorMessage = (_errorMessage ?? "") + "\nCould not load previous answers: $e";
        });
      }
      
      
      try {
        final streakInfo = await _getCurrentStreakInfo();
        _currentStreak = streakInfo['streak'];
        _isInGracePeriod = streakInfo['isInGracePeriod'];
        print("Current streak: $_currentStreak, in grace period: $_isInGracePeriod");
      } catch (e) {
        print("Error loading streak info: $e");
      }
    } catch (e) {
      print("General error in _loadData: $e");
      setState(() {
        _errorMessage = "Something went wrong: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showAnswerComparisonSheet() async {
  
  final allAnswers = await getAllAnswersForCurrentQuestion();
  
  if (allAnswers.isEmpty || !mounted) return;
  
  
  allAnswers.sort((a, b) => b.dateAnswered.compareTo(a.dateAnswered));
  
  if (mounted) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.75,
        child: AnswerComparisonSheet(
          currentQuestion: _currentQuestion,
          allAnswers: allAnswers,
        ),
      ),
    );
  }
}




Future<List<QuestionAnswer>> getAllAnswersForCurrentQuestion() async {
  final now = DateTime.now();
  final questionKey = _getQuestionKey(now);
  
  final answersBox = Hive.box('questionAnswers');
  final rawAnswers = answersBox.get(questionKey) ?? [];
  
  List<QuestionAnswer> answers = [];
  if (rawAnswers is List) {
    answers = rawAnswers.map((raw) {
      if (raw is Map) {
        return QuestionAnswer.fromJson(Map<String, dynamic>.from(raw));
      }
      return null;
    }).whereType<QuestionAnswer>().toList();
  }
  
  return answers;
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

  
  Future<Map<String, dynamic>?> _checkStreakMilestone(int newStreak) async {
    
    final unlockedReward = await checkAndUnlockReward(newStreak);
    
    if (unlockedReward != null) {
      return {
        'title': unlockedReward.title,
        'avatarImage': unlockedReward.avatarImagePath,
        'description': unlockedReward.description
      };
    }
    
    return null;
  }

  Future<void> _submitAnswer() async {
  if (_answerController.text.isEmpty || _isSubmitting) return;
  
  setState(() {
    _isSubmitting = true;
    _errorMessage = null;
  });

  try {
    
    final String answer = _answerController.text;
    setState(() {
      _currentAnswer = answer;
      _answerController.clear();
      _isEditing = false;
    });
    
    
    final saveAnswerFuture = saveAnswerForToday(answer);
    
    
    final notificationService = NotificationService();
    
    
    
    notificationService.cancelQuestionReminders().catchError((error) {
      print("Error canceling question reminders: $error");
      
    });
    
    notificationService.scheduleJournalReminder().catchError((error) {
      print("Error scheduling journal reminder: $error");
      
    });
    
    notificationService.scheduleRandomGrowthFact().catchError((error) {
      print("Error scheduling growth fact: $error");
      
    });
    
    
    await saveAnswerFuture;
    
    
    _getCurrentStreakInfo().then((streakInfo) async {
      
      if (mounted) {
        final newStreak = streakInfo['streak'];
        setState(() {
          _currentStreak = newStreak;
          _isInGracePeriod = false; 
        });
        
        
        final badgeInfo = await _checkStreakMilestone(newStreak);
        
        if (badgeInfo != null && mounted) {
          
          if (context.mounted) {
            showDialog(
              context: context,
              builder: (dialogContext) => BadgeCelebrationScreen(
                badgeTitle: badgeInfo['title'] as String,
                badgeDescription: badgeInfo['description'] as String,
                avatarImage: badgeInfo['avatarImage'] as String,
              ),
            );
          }
        }
      }
    });
    
    
    
    if (mounted) {
      Future.delayed(const Duration(milliseconds: 500), () {
      });
    }
    
  } catch (e) {
    print("Error saving answer: $e");
    if (mounted) {
      setState(() {
        _errorMessage = "Could not save your answer: ${e.toString()}";
      });
    }
  } finally {
    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}

  
  Future<Map<String, dynamic>> _getCurrentStreakInfo() async {
    final now = DateTime.now();
    DateTime currentDate = DateTime(now.year, now.month, now.day);
    
    int streak = 0;
    bool isInGracePeriod = false;
    
    
    final todayAnswer = await getAnswerForDate(currentDate);
    if (todayAnswer != null && todayAnswer.isNotEmpty) {
      
      streak = 1;
    } else {
      
      final yesterday = currentDate.subtract(const Duration(days: 1));
      final yesterdayAnswer = await getAnswerForDate(yesterday);
      
      if (yesterdayAnswer != null && yesterdayAnswer.isNotEmpty) {
        
        isInGracePeriod = true;
        
        
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

    return {
      'streak': streak,
      'isInGracePeriod': isInGracePeriod
    };
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _answerController.text = _currentAnswer ?? '';
    });
    
    
    if (_isInGracePeriod) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Answer today to maintain your streak!'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _answerController.clear();
    });
  }

  void _togglePreviousAnswers() {
    setState(() {
      _showPreviousAnswers = !_showPreviousAnswers;
    });
  }

  @override
Widget build(BuildContext context) {
  if (_isLoading) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );
  }

  return Scaffold(
    backgroundColor: Theme.of(context).colorScheme.background,
    appBar: AppBar(
      centerTitle: true,
      backgroundColor: Theme.of(context).colorScheme.background,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 10,),
          Text(
            DateFormat('MMMM d').format(DateTime.now()),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onBackground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      actions: [
        if (_previousAnswers.isNotEmpty)
          IconButton(
            icon: Icon(
              _showPreviousAnswers 
                  ? Icons.history 
                  : Icons.history_outlined,
              color: Theme.of(context).colorScheme.secondary,
            ),
            onPressed: _togglePreviousAnswers,
            tooltip: 'Previous years',
          ),
      ],
    ),
    
    body: Stack(
      children: [
        
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (_errorMessage != null)
                      Container(
                        margin: EdgeInsets.only(bottom: 16),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade800),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: Text(
                        _currentQuestion,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 15),
                    if (_currentAnswer != null && !_isEditing)
                      Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Today\'s Answer:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Theme.of(context).colorScheme.secondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _currentAnswer!,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: _startEditing,
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(context).colorScheme.secondary,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text('Edit Answer'),
                          ),
                        ],
                      ),
                    if (_currentAnswer == null || _isEditing)
                      Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _answerController,
                              minLines: 1,
                              maxLines: 8,
                              decoration: InputDecoration(
                                hintText: 'Type your answer...',
                                hintStyle: TextStyle(
                                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
                                ),
                                contentPadding: const EdgeInsets.all(20),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isEditing)
                                TextButton(
                                  onPressed: _cancelEditing,
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                                  ),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onBackground,
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: _isSubmitting ? null : _submitAnswer,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.secondary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: _isSubmitting
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ): Text(_isEditing ? 'Update' : 'Save'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    if (_showPreviousAnswers && _previousAnswers.isNotEmpty)
                      _buildPreviousAnswersSection(),
                      
                    
                    SizedBox(height: _currentAnswer != null ? 80 : 0),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        
        if (_currentAnswer != null)
          Positioned(
            bottom: 100,  
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedSeeAllButton(
                onPressed: _showAnswerComparisonSheet,
              ),
            ),
          ),
      ],
    ),
  );
}

  Widget _buildPreviousAnswersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Text(
          'Previous Years:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _previousAnswers.length,
          itemBuilder: (context, index) {
            final answer = _previousAnswers[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('MMMM d, yyyy').format(answer.dateAnswered),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    answer.answer,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }
}
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:woke/mood_chart.dart';
import 'package:woke/mood_hive.dart';
import 'package:woke/question_hive.dart';
import 'package:woke/journal_hive.dart';
import 'package:woke/ai_service.dart';
import 'package:woke/growth_widgets.dart';
import 'package:woke/badge_detail.dart';
import 'package:woke/rewards_hive.dart'; 

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  
  Future<GrowthAnalysis>? _growthAnalysisFuture;
  bool _isFirstLoad = true;
  List<Reward> _rewards = []; 

  @override
  void initState() {
    super.initState();
    
    _loadGrowthAnalysis();
    
    _loadRewards();
  }

  
  Future<void> _loadRewards() async {
    setState(() {
      _rewards = getAllRewards();
    });
  }

  void _loadGrowthAnalysis() {
    setState(() {
      _growthAnalysisFuture = AiService.analyzeUserProgress();
      _isFirstLoad = false;
    });
  }

  
  Future<int> getTotalWordsWritten() async {
    
    final journalEntries = await getAllJournalEntries();
    int totalWords = journalEntries.fold(0, (sum, entry) => sum + entry.entry.split(' ').length);
    
    
    final answersBox = Hive.box('questionAnswers');
    final allAnswerKeys = answersBox.keys.where((key) => key.toString().startsWith('day_') || key == 'leapDay');
    
    for (var key in allAnswerKeys) {
      final answers = answersBox.get(key) ?? [];
      for (var answer in answers) {
        if (answer is Map) {
          final qa = QuestionAnswer.fromJson(Map<String, dynamic>.from(answer));
          totalWords += qa.answer.split(' ').length;
        }
      }
    }
    
    return totalWords;
  }

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

    return {
      'streak': streak,
      'isInGracePeriod': isInGracePeriod,
      'needsTodayEntry': needsTodayEntry
    };
  }

  
  Future<List<MoodEntry>> getRecentMoodEntries() async {
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final twoWeeksAgo = today.subtract(const Duration(days: 14));
    
    
    final entries = MoodService.getAllMoodEntries();
    
    
    return entries.where((entry) {
      final entryDate = DateTime(entry.date.year, entry.date.month, entry.date.day);
      return !entryDate.isBefore(twoWeeksAgo) && !entryDate.isAfter(today);
    }).toList();
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

  
  List<Color> _getCategoryColors(BuildContext context) {
    return [
      Theme.of(context).colorScheme.secondary,
      Theme.of(context).colorScheme.tertiary,
      Colors.orange,
      Colors.green,
      Colors.red,
      Colors.blue,
      Colors.amber,
    ];
  }

  
  IconData _getInsightIcon(int index) {
    final icons = [
      Icons.psychology,
      Icons.lightbulb,
      Icons.trending_up,
      Icons.visibility,
      Icons.favorite,
      Icons.stars,
      Icons.navigation,
    ];
    return icons[index % icons.length];
  }

  Widget _buildStreakWidget(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: getCurrentStreakInfo(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(24.0),
            height: 150, 
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        
        final data = snapshot.data ?? {'streak': 0, 'isInGracePeriod': false, 'needsTodayEntry': false};
        final streak = data['streak'] ?? 0;
        final isInGracePeriod = data['isInGracePeriod'] ?? false;
        
        return GestureDetector(
          onTap: () {
            
            if (isInGracePeriod) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Answer today\'s question to maintain streak!'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.all(24.0),
            height: 150, 
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Current Streak',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.8),
                    fontSize: 14
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 50, 
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      (streak != 1) ? '$streak days' : '$streak day',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isInGracePeriod
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        elevation: 0,
        title: Text(
          "Analytics",
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Progress',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              
              
              Row(
                children: [
                  
                  Expanded(
                    child: _buildStreakWidget(context)
                  ),
                  const SizedBox(width: 16),
                  
                  
                  Expanded(
                    child: FutureBuilder<int>(
                      future: getTotalWordsWritten(),
                      builder: (context, snapshot) {
                        return Container(
                          padding: const EdgeInsets.all(24.0),
                          height: 150, 
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(16.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Words Written',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.8),
                                  fontSize: 14
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 50, 
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '${snapshot.data ?? 0}',
                                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.secondary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Growth Analysis',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  
                  if (!_isFirstLoad)
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadGrowthAnalysis,
                      tooltip: 'Refresh analysis',
                    ),
                ],
              ),
              const SizedBox(height: 16),
              
              
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: FutureBuilder<GrowthAnalysis>(
                  future: _growthAnalysisFuture,
                  builder: (context, snapshot) {
                    
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 250,
                        child: AnalysisLoadingWidget(),
                      );
                    } else if (snapshot.hasError) {
                      return SizedBox(
                        height: 250,
                        child: AnalysisErrorWidget(
                          message: 'Unable to generate analysis. Please check your connection and API key.',
                          onRetry: _loadGrowthAnalysis,
                        ),
                      );
                    } else if (!snapshot.hasData || 
                              snapshot.data!.summary.isEmpty && 
                              snapshot.data!.insights.isEmpty) {
                      return const SizedBox(
                        height: 250,
                        child: NoDataWidget(),
                      );
                    }
                    
                    
                    final analysis = snapshot.data!;
                    final colors = _getCategoryColors(context);
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        
                        if (analysis.summary.isNotEmpty) ...[
                          Text(
                            analysis.summary,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        
                        
                        if (analysis.insights.isNotEmpty) ...[
                          Text(
                            'Key Insights',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...List.generate(
                            analysis.insights.length,
                            (index) => InsightCard(
                              insight: analysis.insights[index],
                              icon: _getInsightIcon(index),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        
                        
                        if (analysis.categories.isNotEmpty) ...[
                          Text(
                            'Themes in Your Entries',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...analysis.categories.entries.map((entry) {
                            final index = analysis.categories.keys.toList().indexOf(entry.key);
                            return CategoryBar(
                              category: entry.key,
                              percentage: entry.value,
                              color: colors[index % colors.length],
                            );
                          }).toList(),
                        ],
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
              
              
              Text(
                'Mood Timeline',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: FutureBuilder<List<MoodEntry>>(
                  future: getRecentMoodEntries(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 180,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    
                    final moodEntries = snapshot.data ?? [];
                    
                    
                    final now = DateTime.now();
                    final currentWeekMonday = now.subtract(Duration(days: now.weekday - 1));
                    
                    return MoodTimelineChart(
                      moodEntries: moodEntries,
                      weekStartDate: currentWeekMonday,
                    );
                  },
                ),
              ),
              
              
              const SizedBox(height: 32),
              Text(
                'Rewards',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              
              _buildRewardsSection(context),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRewardsSection(BuildContext context) {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center, 
        spacing: 16,
        runSpacing: 16,
        children: [
          BadgeItem(
            title: 'Initiate',
            avatarImage: 'assets/initiate_av.png',
            iconImage: 'assets/initiate_ic.png',
            label: '5 Days',
            criteria: 'Complete a 5-day streak of daily reflections.',
            description: 'You\'ve taken your first steps on the journey of self-discovery and growth.',
            isUnlocked: getReward('Initiate')?.isUnlocked ?? false,
          ),
          BadgeItem(
            title: 'Seeker',
            avatarImage: 'assets/seeker_av.png',
            iconImage: 'assets/seeker_ic.png',
            label: '15 Days',
            criteria: 'Complete a 15-day streak of daily reflections.',
            description: 'You\'re actively seeking deeper understanding and personal growth.',
            isUnlocked: getReward('Seeker')?.isUnlocked ?? false,
          ),
          BadgeItem(
            title: 'Observer',
            avatarImage: 'assets/observer_av.png',
            iconImage: 'assets/observer_ic.png',
            label: '1 Month',
            criteria: 'Complete a 30-day streak of daily reflections.',
            description: 'You\'ve developed the discipline to observe your thoughts and patterns consistently.',
            isUnlocked: getReward('Observer')?.isUnlocked ?? false,
          ),
          BadgeItem(
            title: 'Reflector',
            avatarImage: 'assets/reflector_av.png',
            iconImage: 'assets/reflector_ic.png',
            label: '3 Months',
            criteria: 'Complete a 90-day streak of daily reflections.',
            description: 'Your commitment to self-reflection has become a cornerstone of your personal growth journey.',
            isUnlocked: getReward('Reflector')?.isUnlocked ?? false,
          ),
          BadgeItem(
            title: 'Guide',
            avatarImage: 'assets/guide_av.png',
            iconImage: 'assets/guide_ic.png',
            label: '6 Months',
            criteria: 'Complete a 180-day streak of daily reflections.',
            description: 'Your insights have deepened to the point where you can guide both yourself and others.',
            isUnlocked: getReward('Guide')?.isUnlocked ?? false,
          ),
          BadgeItem(
            title: 'Sage',
            avatarImage: 'assets/sage_av.png',
            iconImage: 'assets/sage_ic.png',
            label: '9 Months',
            criteria: 'Complete a 270-day streak of daily reflections.',
            description: 'You\'ve accumulated profound wisdom through consistent introspection and mindfulness.',
            isUnlocked: getReward('Sage')?.isUnlocked ?? false,
          ),
          BadgeItem(
            title: 'Alchemist',
            avatarImage: 'assets/alchemist_av.png',
            iconImage: 'assets/alchemist_ic.png',
            label: '1 Year',
            criteria: 'Complete a 365-day streak of daily reflections.',
            description: 'You\'ve mastered the art of transforming daily reflections into profound personal growth.',
            isUnlocked: getReward('Alchemist')?.isUnlocked ?? false,
          ),
        ],
      ),
    );
  }
}

class BadgeItem extends StatelessWidget {
  final String avatarImage;    
  final String iconImage;      
  final String label;          
  final bool isUnlocked;
  final String title;          
  final String criteria;       
  final String description;    

  const BadgeItem({
    super.key,
    required this.avatarImage,
    required this.iconImage,
    required this.label,
    required this.title,
    required this.criteria,
    required this.description,
    this.isUnlocked = false,
  });

  void _showBadgeDetails(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return BadgeDetailDialog(
          title: title,
          criteria: criteria,
          description: description,
          avatarImage: avatarImage,
          iconImage: iconImage,
          isUnlocked: isUnlocked,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _showBadgeDetails(context),
          onLongPress: () => _showBadgeDetails(context),
          child: Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: isUnlocked 
                  ? Theme.of(context).colorScheme.secondary.withOpacity(0.1)
                  : Theme.of(context).colorScheme.primary.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(
                color: isUnlocked 
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).colorScheme.onBackground.withOpacity(0.1),
                width: 2,
              ),
            ),
            child: Center(
              child: Image.asset(
                isUnlocked ? avatarImage : iconImage,
                width: 52,
                height: 52,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        
        if (isUnlocked)
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
      ],
    );
  }
}
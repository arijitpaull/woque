import 'package:flutter/material.dart';
import 'package:woke/mood.dart';
import 'package:woke/streak.dart' as Analytics;
import 'package:woke/user_hive.dart';
import 'package:woke/mood_hive.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:woke/rewards_hive.dart'; 

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late UserData _userData;
  List<String> _todaysMoods = [];
  String _moodDisplayText = "No mood recorded today";
  bool _isAboutExpanded = false;
  
  final ScrollController _scrollController = ScrollController();
  
  Reward? _highestReward;
  
  
  final String _privacyPolicyUrl = 'https://www.freeprivacypolicy.com/live/ee0cf789-36ce-4d10-a23e-51946866520c';
  final String _termsOfServiceUrl = 'https://www.freeprivacypolicy.com/live/d3da5ca4-fc6a-42f1-84de-916f5e2ed082';
  
  @override
  void initState() {
    super.initState();
    _userData = getUserData();
    
    _loadTodaysMoods();
    _initializeStreakData();
    _loadHighestReward();
  }

  
  void _loadHighestReward() {
    setState(() {
      _highestReward = getHighestUnlockedReward();
      
      
      if (_highestReward != null) {
        if (_userData.title != _highestReward!.title) {
          _updateUserTitle(_highestReward!.title);
        }
      }
    });
  }

  
  Future<void> _updateUserTitle(String title) async {
    
    final updatedUserData = _userData.copyWith(title: title);
    
    setState(() {
      _userData = updatedUserData;
    });
    
    await updateUserTitle(title);
  }

  @override
  void dispose() {
    
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeStreakData() async {
    final currentStreak = await Analytics.getCurrentStreak();
    if (currentStreak > _userData.maxStreak) {
      await _updateMaxStreak(currentStreak);
    }
  }

  Future<void> _updateMaxStreak(int newStreak) async {
    
    final updatedUserData = _userData.copyWith(maxStreak: newStreak);
    
    setState(() {
      _userData = updatedUserData;
    });
    
    
    await updateMaxStreak(newStreak);
  }

  void _loadTodaysMoods() {
    try {
      final today = DateTime.now();
      final moodEntry = MoodService.getMoodEntryForDate(today);
      
      if (moodEntry != null) {
        setState(() {
          _todaysMoods = moodEntry.moods.map((mood) {
            
            return mood.toString(); 
          }).where((mood) => mood.isNotEmpty).toList();
          
          _updateMoodDisplayText();
        });
      } else {
        setState(() {
          _moodDisplayText = "No mood recorded today";
        });
      }
    } catch (e) {
      print('Error loading moods: $e');
      setState(() {
        _moodDisplayText = "Error loading mood data";
      });
    }
  }

  
  final Map<String, String> _moodEmojis = {
    'Happy': '😊',
    'Sad': '😢',
    'Nervous': '😰',
    'Confused': '😕',
    'Excited': '🤩',
    'Lazy': '😴',
    'Bored': '🥱',
    'Active': '💪',
    'Overwhelmed': '😫',
    'Calm': '😌',
    'Anxious': '😥',
    'Grateful': '🙏',
    'Tired': '😩',
    'Focused': '🧐',
    'Energetic': '⚡',
  };

  void _updateMoodDisplayText() {
    if (_todaysMoods.isEmpty) {
      _moodDisplayText = "No mood recorded today";
      return;
    }
    
    try {
      List<String> emojiList = [];
      
      for (var mood in _todaysMoods) {
        String emoji = _moodEmojis[mood] ?? '❓';
        emojiList.add(emoji);
      }
      
      if (emojiList.isNotEmpty) {
        _moodDisplayText = "Today's mood: ${emojiList.join(' ')}";
      } else {
        _moodDisplayText = "Today's mood data is incomplete";
      }
    } catch (e) {
      print('Error formatting mood text: $e');
      _moodDisplayText = "Today's mood data is unavailable";
    }
  }

  Future<void> _showEditTodaysMood(BuildContext context) async {
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.8,
        minChildSize: 0.5,
        builder: (_, controller) => MoodCheckInSheet(
          scrollController: controller,
          initialMoods: _todaysMoods,
          isEditing: true,
          onComplete: (selectedMoods) {
            Navigator.pop(context, selectedMoods);
          },
        ),
      ),
    );

    
    if (result != null) {
      await MoodService.saveMoods(result);
      
      _loadTodaysMoods();
      
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mood updated successfully'),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> _showNameChangeDialog() async {
    final TextEditingController nameController = TextEditingController(text: _userData.name ?? '');
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          "Change Name",
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            hintText: "Enter your name",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.secondary,
                width: 2,
              ),
            ),
          ),
          style: Theme.of(context).textTheme.bodyLarge,
          maxLength: 30,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              
              await updateUserName(nameController.text.trim());
              
              
              setState(() {
                _userData = getUserData();
              });
              
              if (context.mounted) {
                Navigator.pop(context);
                _showNameUpdateSuccess();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Theme.of(context).colorScheme.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
  
  void _showNameUpdateSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Name update successfully'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  
  Future<void> _launchUrl(String url) async {
    try {
      
      final Uri uri = Uri.parse(url);
      
      
      if (await canLaunchUrl(uri)) {
        
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      print('Error launching URL: $e');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open link. Please try again later.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _getAvatarContent(BuildContext context) {
    
    if (_highestReward != null) {
      return Image.asset(_highestReward!.avatarImagePath,fit: BoxFit.fill,);
    }
    
    
    return Text(
      _userData.name?.isNotEmpty == true 
          ? _userData.name![0].toUpperCase() 
          : "?",
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.secondary,
      ),
    );
  }

  
  void _scrollToExpandedSection() {
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        final currentPosition = _scrollController.position.pixels;
        final scrollAmount = 200.0; 
        
        _scrollController.animateTo(
          currentPosition + scrollAmount,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.background,
        elevation: 0,
        title: Text(
          "Settings",
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              
              
              _buildProfileCard(context),
              
              const SizedBox(height: 24),
              
              
              Expanded(
                child: ListView(
                  controller: _scrollController, 
                  children: [
                    const SizedBox(height: 16),
                    _buildSettingCard(
                      context,
                      title: "Max Streak: ${_userData.maxStreak} ${_userData.maxStreak == 1 ? 'day' : 'days'}",
                      icon: Icons.local_fire_department_outlined,
                      onTap: () {
                      },  
                    ),
                    const SizedBox(height: 16),
                    _buildSettingCard(
                      context,
                      title: _moodDisplayText,
                      icon: Icons.mood,
                      onTap: () {
                        _showEditTodaysMood(context);
                      },
                      hasRightArrow: true,
                    ),
                    const SizedBox(height: 16),
                    _buildSettingCard(
                      context,
                      title: "Privacy Policy",
                      icon: Icons.privacy_tip_outlined,
                      onTap: () {
                        
                        _launchUrl(_privacyPolicyUrl);
                      },
                      hasRightArrow: true,
                    ),
                    const SizedBox(height: 16),
                    _buildSettingCard(
                      context,
                      title: "Terms of Service",
                      icon: Icons.description_outlined,
                      onTap: () {
                        
                        _launchUrl(_termsOfServiceUrl);
                      },
                      hasRightArrow: true,
                    ),
                    const SizedBox(height: 16),
                    
                    _buildExpandableAboutCard(context),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildProfileCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        onTap: _showNameChangeDialog,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: _getAvatarContent(context),
              ),
            ),
            const SizedBox(width: 20),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _userData.name?.isNotEmpty == true 
                        ? _userData.name! 
                        : "Set Your Name",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userData.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "Tap to edit name",
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingCard(
    BuildContext context, {
    required String title,
    String? subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool hasRightArrow = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.secondary,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onBackground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (hasRightArrow)
              Icon(
                Icons.keyboard_arrow_right,
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildExpandableAboutCard(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          
          GestureDetector(
            onTap: () {
              setState(() {
                _isAboutExpanded = !_isAboutExpanded;
                
                
                if (_isAboutExpanded) {
                  _scrollToExpandedSection();
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.secondary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      "About Woque",
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onBackground,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    _isAboutExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                  ),
                ],
              ),
            ),
          ),
          
          
          AnimatedCrossFade(
            firstChild: const SizedBox(height: 0),
            secondChild: Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    "Woque is an app that helps you understand yourself better by:",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildAboutItem(context, "Asking one thoughtful question daily to promote self-reflection"),
                  const SizedBox(height: 8),
                  _buildAboutItem(context, "Tracking your mood patterns over time"),
                  const SizedBox(height: 8),
                  _buildAboutItem(context, "Analyzing your responses and emotional data"),
                  const SizedBox(height: 8),
                  _buildAboutItem(context, "Visualizing your progress with intuitive charts and progress bars"),
                  const SizedBox(height: 8),
                  _buildAboutItem(context, "Providing insights to help you grow and understand yourself"),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Your journey of self-discovery begins with a single question each day.",
                      style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: _isAboutExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAboutItem(BuildContext context, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check_circle,
          size: 16,
          color: Theme.of(context).colorScheme.secondary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.9),
            ),
          ),
        ),
      ],
    );
  }
}
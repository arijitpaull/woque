import 'package:flutter/material.dart';
import 'package:woke/mood_hive.dart';

class MoodCheckIn extends StatefulWidget {
  final Function() onComplete;

  const MoodCheckIn({
    super.key,
    required this.onComplete,
  });

  static Future<void> showDailyCheckIn(BuildContext context) async {
    
    if (MoodService.hasRecordedMoodToday()) {
      return;
    }

    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.8,
        minChildSize: 0.5,
        builder: (_, controller) => MoodCheckInSheet(
          scrollController: controller,
          initialMoods: const [],
          isEditing: false,
          onComplete: (selectedMoods) {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  @override
  State<MoodCheckIn> createState() => _MoodCheckInState();
}

class _MoodCheckInState extends State<MoodCheckIn> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class MoodCheckInSheet extends StatefulWidget {
  final ScrollController scrollController;
  final Function(List<String>) onComplete;
  final List<String> initialMoods;
  final bool isEditing;

  const MoodCheckInSheet({
    super.key,
    required this.scrollController,
    required this.onComplete,
    this.initialMoods = const [],
    this.isEditing = false,
  });

  @override
  State<MoodCheckInSheet> createState() => _MoodCheckInSheetState();
}

class _MoodCheckInSheetState extends State<MoodCheckInSheet> with SingleTickerProviderStateMixin {
  late List<String> selectedMoods;
  bool _showScrollIndicator = true;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    
    selectedMoods = List<String>.from(widget.initialMoods);
    
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  
  final List<Map<String, dynamic>> moods = [
    {'name': 'Happy', 'emoji': '😊'},
    {'name': 'Sad', 'emoji': '😢'},
    {'name': 'Nervous', 'emoji': '😰'},
    {'name': 'Confused', 'emoji': '😕'},
    {'name': 'Excited', 'emoji': '🤩'},
    {'name': 'Lazy', 'emoji': '😴'},
    {'name': 'Bored', 'emoji': '🥱'},
    {'name': 'Active', 'emoji': '💪'},
    {'name': 'Overwhelmed', 'emoji': '😫'},
    {'name': 'Calm', 'emoji': '😌'},
    {'name': 'Anxious', 'emoji': '😥'},
    {'name': 'Grateful', 'emoji': '🙏'},
    {'name': 'Tired', 'emoji': '😩'},
    {'name': 'Focused', 'emoji': '🧐'},
    {'name': 'Energetic', 'emoji': '⚡'},
  ];

  Future<void> _saveMoods() async {
    if (selectedMoods.isEmpty) {
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one mood')),
      );
      return;
    }

    try {
      if (!widget.isEditing) {
        
        await MoodService.saveMoods(selectedMoods);
      }
      
      
      widget.onComplete(selectedMoods);
    } catch (e) {
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save moods: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
          ),
          
          
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
            child: Text(
              widget.isEditing ? 'Update your mood' : 'How are you feeling today?',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
            child: Text(
              'Select all moods that apply',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.secondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      
                      if (notification is ScrollUpdateNotification) {
                        final metrics = notification.metrics;
                        if (metrics.pixels > 0 && 
                            metrics.pixels >= metrics.maxScrollExtent - 100) {
                          if (_showScrollIndicator) {
                            setState(() {
                              _showScrollIndicator = false;
                            });
                          }
                        } else if (!_showScrollIndicator && metrics.pixels < metrics.maxScrollExtent - 150) {
                          
                          setState(() {
                            _showScrollIndicator = true;
                          });
                        }
                      }
                      return false;
                    },
                    child: SingleChildScrollView(
                      controller: widget.scrollController,
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 15,
                        alignment: WrapAlignment.center,
                        children: moods.map((mood) {
                          final bool isSelected = selectedMoods.contains(mood['name']);
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  selectedMoods.remove(mood['name']);
                                } else {
                                  selectedMoods.add(mood['name']);
                                }
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.tertiary
                                    : Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(50),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .tertiary
                                              .withOpacity(0.3),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    mood['emoji'],
                                    style: const TextStyle(fontSize: 22),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    mood['name'],
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Theme.of(context).colorScheme.onBackground,
                                      fontWeight:
                                          isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                
                
                if (_showScrollIndicator)
                  Positioned(
                    bottom: 10,
                    child: AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _animation.value),
                          child: child,
                        );
                      },
                      child: AnimatedOpacity(
                        opacity: _showScrollIndicator ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.tertiary.withOpacity(0.8),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          
          Padding(
            padding: const EdgeInsets.all(24),
            child: ElevatedButton(
              onPressed: _saveMoods,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.tertiary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                elevation: 4,
              ),
              child: Text(
                widget.isEditing ? 'Update' : 'Submit',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
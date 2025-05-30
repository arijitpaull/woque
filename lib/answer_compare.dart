import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:woke/ai_service.dart';
import 'package:woke/question_hive.dart';

class AnimatedSeeAllButton extends StatefulWidget {
  final VoidCallback onPressed;

  const AnimatedSeeAllButton({
    Key? key,
    required this.onPressed,
  }) : super(key: key);

  @override
  State<AnimatedSeeAllButton> createState() => _AnimatedSeeAllButtonState();
}

class _AnimatedSeeAllButtonState extends State<AnimatedSeeAllButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;
  late Animation<double> _shineAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0.0, end: 8.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _shineAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 1.0, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -_bounceAnimation.value),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              
              TextButton.icon(
                onPressed: widget.onPressed,
                icon: Icon(
                  Icons.arrow_upward,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                label: Text(
                  'see all answers',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class AnswerComparisonSheet extends StatefulWidget {
  final String currentQuestion;
  final List<QuestionAnswer> allAnswers;

  const AnswerComparisonSheet({
    Key? key,
    required this.currentQuestion,
    required this.allAnswers,
  }) : super(key: key);

  @override
  State<AnswerComparisonSheet> createState() => _AnswerComparisonSheetState();
}

class _AnswerComparisonSheetState extends State<AnswerComparisonSheet> {
  
  Set<int> _expandedItems = {};
  
  Set<int> _loadingItems = {};
  
  Map<int, String> _analysisResults = {};

  Future<void> _toggleItem(int index) async {
    
    if (index == 0) return;
    
    setState(() {
      if (_expandedItems.contains(index)) {
        _expandedItems.remove(index);
      } else {
        _expandedItems.add(index);
        
        
        if (!_analysisResults.containsKey(index)) {
          _loadingItems.add(index);
          _loadAnalysis(index);
        }
      }
    });
  }
  
  Future<void> _loadAnalysis(int index) async {
    
    final currentAnswer = widget.allAnswers[0].answer;
    final currentDate = widget.allAnswers[0].dateAnswered;
    final previousAnswer = widget.allAnswers[index].answer;
    final previousDate = widget.allAnswers[index].dateAnswered;
    
    final analysis = await AiService.compareAnswers(
      currentAnswer, 
      previousAnswer, 
      widget.currentQuestion, 
      currentDate, 
      previousDate
    );
    
    if (mounted) {
      setState(() {
        _analysisResults[index] = analysis;
        _loadingItems.remove(index);
      });
    }
  }

  @override
Widget build(BuildContext context) {
  return Container(
    constraints: BoxConstraints(
      minHeight: MediaQuery.of(context).size.height * 0.6,
    ),
    decoration: BoxDecoration(
      color: Color(0xFFF5F2ED), 
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
    ),
    child: IntrinsicHeight(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Your Answers',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54, 
                  ),
                ),
              ],
            ),
          ),
          
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                ),
              ),
              child: Text(
                widget.currentQuestion,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  color: Colors.black87, 
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          
          
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: widget.allAnswers.length,
              itemBuilder: (context, index) {
                final answer = widget.allAnswers[index];
                final isCurrentAnswer = index == 0;
                final isExpanded = _expandedItems.contains(index);
                final isLoading = _loadingItems.contains(index);
                
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, top: 16.0, bottom: 4.0),
                      child: Text(
                        DateFormat('MMMM d, yyyy').format(answer.dateAnswered),
                        style: TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    
                    Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 8),
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: isCurrentAnswer ? null : () => _toggleItem(index),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  
                                  if (isCurrentAnswer)
                                    Container(
                                      margin: const EdgeInsets.only(right: 8, top: 2),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Color(0xFFE5D6C6), 
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'Current',
                                        style: TextStyle(
                                          color: Colors.black54,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  Expanded(
                                    child: Text(
                                      answer.answer,
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  if (!isCurrentAnswer)
                                    Icon(
                                      isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                      color: Colors.black54,
                                    ),
                                ],
                              ),
                              
                              
                              if (isExpanded && !isCurrentAnswer)
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.only(top: 16),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFE5D6C6).withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: isLoading
                                      ? const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE5D6C6)),
                                            ),
                                          ),
                                        )
                                      : Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Comparison with current answer:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: Colors.black54,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              _analysisResults[index] ?? 'Analysis not available.',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                height: 1.4,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    ),
  );
}
}
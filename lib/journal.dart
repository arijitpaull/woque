import 'package:flutter/material.dart';
import 'package:woke/journal_hive.dart';
import 'dart:math';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> with TickerProviderStateMixin {
  Set<String> _selectedEntryIds = {}; 
  bool _isSelecting = false; 
  Map<String, int> _promptCounts = {};
  final List<String> _allPrompts = [
    "What surprised you today?",
    "What are you grateful for?",
    "What challenged you today?",
    "What did you learn today?",
    "How did you take care of yourself today?",
    "What made you smile today?",
    "What's something you're looking forward to?",
    "If you could change one thing about today, what would it be?",
    "What was the most peaceful moment of your day?",
    "What's a small win you had today?",
    "What's something you're proud of?",
    "What's something you want to remember about today?",
    "What's something that made you laugh today?",
    "What's a challenge you're currently facing?",
    "How did you show kindness today?",
    "What's something that inspired you recently?",
    "What's a question you're pondering lately?",
    "What's something you wish you had done differently today?",
    "What's a boundary you need to set or maintain?",
    "What's a goal you're working towards?",
    "What's something that brought you comfort today?",
    "What's something new you tried recently?",
    "What's a fear you faced today?",
    "What's something you did today that aligned with your values?",
    "What's a habit you're trying to build or break?",
    "What's something you observed in nature today?",
    "What's a conversation that stuck with you today?",
    "What's something you read or heard that resonated with you?",
    "What's a decision you need to make soon?",
    "What's something you're curious about?",
    "What made you feel energized today?",
    "What drained your energy today?",
    "What's something you're avoiding?",
    "What's a relationship you'd like to nurture?",
    "What did you do for self-care today?",
    "What's something that's been on your mind lately?",
    "What's a skill you'd like to develop?",
    "What's something you need to let go of?",
    "What's a belief that was challenged today?",
    "What's something you're worried about?",
    "What's something you're excited about?",
    "What's something you need more of in your life?",
    "What's something you need less of in your life?",
    "What's a change you've noticed in yourself recently?",
    "What's a quality you appreciate in yourself?",
    "What's a quality you appreciate in someone else?",
    "What's something you want to explore more deeply?",
    "What's a pattern you've noticed in your behavior?",
    "What's something that felt meaningful today?",
    "What's something you're struggling with?",
    "What's something you did well today?",
    "What's something that surprised you about yourself?",
    "What's a lesson you keep relearning?",
    "What's a moment you felt fully present today?",
    "What's something that made you feel connected to others?",
    "What's something that made you feel disconnected from others?",
    "What's something you're learning about yourself?",
    "What's something you want to express but haven't?",
    "What's a thought that keeps coming back to you?",
    "What's a small pleasure you enjoyed today?",
    "What's something that challenged your perspective?",
    "What's a strength you used today?",
    "What's an opportunity you see ahead?",
    "What's a risk you took or want to take?",
    "What's something you accomplished today?",
    "What's something you wish you had more time for?",
    "What's a sound, smell, taste, or feeling you noticed today?",
    "What's something you're thankful for that you normally take for granted?",
    "What's something you did today that was just for you?",
    "What's something you're still figuring out?",
    "What's a moment when you felt strong today?",
    "What's a moment when you felt vulnerable today?",
    "What's something you need to forgive yourself for?",
    "What's something you need to forgive someone else for?",
    "What's something you observed about your emotions today?",
    "What's something that made you feel grounded today?",
    "What's something that made you feel unsteady today?",
    "What's something you're resisting?",
    "What's something that's working well in your life right now?",
    "What's something that's not working in your life right now?",
    "What's something you'd like to celebrate?",
    "What's a truth you're avoiding?",
    "What's a memory that came up for you today?",
    "What's a hope you have for tomorrow?",
    "What's a boundary that was crossed today?",
    "What's a moment you felt authentic today?",
    "What's a moment you didn't feel like yourself?",
    "What's a compliment you received that meant something to you?",
    "What's a dream or idea you've been nurturing?",
    "What's something you did today that required courage?",
    "What's something you're overthinking?",
    "What's something you need to be honest about?",
    "What's something that feels unresolved?",
    "What's a connection you made today?",
    "What's something you need to accept?",
    "What's something you need to release?",
    "What's a choice you made today that you're proud of?",
    "What's something you did today that reflected your values?",
    "What's a situation where you compromised your values today?"
  ];
  
  List<String> _currentPrompts = [];
  final PageController _pageController = PageController();
  final TextEditingController _journalController = TextEditingController();
  String? _selectedPrompt;
  bool _showAllEntries = false;
  int _currentPage = 0;
  bool _isGeneratingPrompts = false;
  double _fontSize = 15.0;
  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];
  bool _useMockImages = false;
  bool _showSwipeIndicator = true;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _generateRandomPrompts();
    
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page?.round() ?? 0;
        _currentPage = _currentPage % _currentPrompts.length;
      });
    });
    _loadPromptCounts();

    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _journalController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadPromptCounts() async {
    final counts = await getPromptEntryCounts();
    setState(() {
      _promptCounts = counts;
    });
  }

  void _generateRandomPrompts() {
  
  
  final random = Random();
  final Set<String> newPrompts = {};
  
  
  while (newPrompts.length < 5) {
    int index = random.nextInt(_allPrompts.length);
    newPrompts.add(_allPrompts[index]);
  }
  
  if (mounted) { 
    setState(() {
      _currentPrompts = newPrompts.toList();
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
      _currentPage = 0;
    });
  }
  
  _loadPromptCounts();
}

  void _showPromptBottomSheet(String prompt) {
    _selectedPrompt = prompt;
    _journalController.clear();
    _selectedImages = [];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      builder: (context) => _buildJournalBottomSheet(),
    );
  }

  Future<void> _pickImage(ImageSource source, StateSetter setBottomSheetState, {bool multiple = false}) async {
    if (_useMockImages) {
      setBottomSheetState(() {
        _selectedImages.add(XFile('mock_image_${DateTime.now().millisecondsSinceEpoch}.jpg'));
      });
      Navigator.pop(context);
      return;
    }
    
    try {
      if (multiple && source == ImageSource.gallery) {
        final List<XFile> images = await _picker.pickMultiImage(
          maxWidth: 1000,
          maxHeight: 1000,
          imageQuality: 85,
        );
        
        if (images.isNotEmpty) {
          setBottomSheetState(() {
            _selectedImages.addAll(images);
          });
          Navigator.pop(context);
        }
      } else {
        final XFile? image = await _picker.pickImage(
          source: source,
          maxWidth: 1000,
          maxHeight: 1000,
          imageQuality: 85,
        );
        
        if (image != null) {
          setBottomSheetState(() {
            _selectedImages.add(image);
          });
          Navigator.pop(context);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e - Using mock images instead'))
      );
      
      setBottomSheetState(() {
        _useMockImages = true;
        _selectedImages.add(XFile('mock_image_${DateTime.now().millisecondsSinceEpoch}.jpg'));
      });
      Navigator.pop(context);
    }
  }

  Widget _buildJournalBottomSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      child: StatefulBuilder(
        builder: (BuildContext context, StateSetter setBottomSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              left: 20,
              right: 20,
              top: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Font Size: ${_fontSize.round()}",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(
                      width: 150,
                      child: Slider(
                        value: _fontSize,
                        min: 12.0,
                        max: 24.0,
                        label: _fontSize.round().toString(),
                        onChanged: (double value) {
                          setBottomSheetState(() {
                            _fontSize = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _selectedPrompt!,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onBackground,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                
                if (_selectedImages.isNotEmpty) ...[
                  Container(
                    height: 120,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (int i = 0; i < _selectedImages.length; i++)
                          GestureDetector(
                            onTap: () => _showFullImage(i, setBottomSheetState),
                            onLongPress: () => _removeImage(i, setBottomSheetState),
                            child: Container(
                              margin: EdgeInsets.only(right: 10),
                              width: 120,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: _useMockImages 
                                  ? Center(
                                      child: Icon(
                                        Icons.image,
                                        size: 50,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    )
                                  : Image.file(
                                      File(_selectedImages[i].path),
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Center(
                                          child: Icon(
                                            Icons.image,
                                            size: 50,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                        );
                                      },
                                    ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _journalController,
                      minLines: null,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: TextStyle(
                        fontSize: _fontSize,
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Write your journal entry...',
                        hintStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
                        ),
                        contentPadding: const EdgeInsets.all(20),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.image,
                        color: Theme.of(context).colorScheme.secondary,
                        size: 28,
                      ),
                      onPressed: () => _showImagePickerOptions(setBottomSheetState),
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () async {
                        if (_journalController.text.isNotEmpty) {
                          final List<String> imagePaths = _selectedImages.map((image) => image.path).toList();
                          await saveJournalEntry(
                            _selectedPrompt!, 
                            _journalController.text,
                            DateTime.now(),
                            imagePaths: imagePaths,
                          );
                          _loadPromptCounts();

                          Navigator.pop(context);
                          setState(() {});
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showAllEntries) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        appBar: AppBar(
  backgroundColor: Theme.of(context).colorScheme.background,
  elevation: 0,
  centerTitle: true,
  leading: _isSelecting 
      ? IconButton(
          icon: Icon(Icons.close),
          onPressed: () {
            setState(() {
              _isSelecting = false;
              _selectedEntryIds.clear();
            });
          },
        )
      : IconButton(
          icon: Icon(Icons.arrow_back_ios_new),
          onPressed: () => setState(() => _showAllEntries = false),
        ),
  title: Text(
    _isSelecting 
        ? "${_selectedEntryIds.length} selected"
        : "Journal Entries",
    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.w600,
    ),
  ),
  actions: [
    if (!_isSelecting)
      IconButton(
        icon: Icon(Icons.delete_outline),
        onPressed: () {
          setState(() {
            _isSelecting = true;
          });
        },
      ),
    if (_isSelecting && _selectedEntryIds.isNotEmpty)
      IconButton(
        icon: Icon(Icons.delete),
        onPressed: () async {
          final shouldDelete = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title:Text("Are you sure?"),
              content: Text((_selectedEntryIds.length==1)?"Delete ${_selectedEntryIds.length} entry?":"Delete ${_selectedEntryIds.length} entries"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text("Cancel", style: TextStyle(color: Color(0xFF5D5348))),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text("Delete", style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
          
          if (shouldDelete ?? false) {
            await deleteJournalEntries(_selectedEntryIds.toList());
            await _loadPromptCounts();
            setState(() {
              _selectedEntryIds.clear();
              _isSelecting = false;
            });
          }
        },
      ),
  ],
),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Expanded(
  child: FutureBuilder<List<JournalEntry>>(
    future: getAllJournalEntries(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.secondary,
          ),
        );
      }

      if (snapshot.data!.isEmpty) {
        return Center(
          child: Text(
            "No journal entries yet",
            style: TextStyle(
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
            ),
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: snapshot.data!.length,
        itemBuilder: (context, index) {
          final entry = snapshot.data![index];
          final isSelected = _selectedEntryIds.contains(entry.id);

          return GestureDetector(
            onLongPress: () {
              setState(() {
                _isSelecting = true;
                _selectedEntryIds.add(entry.id);
              });
            },
            onTap: () {
              if (_isSelecting) {
                setState(() {
                  if (isSelected) {
                    _selectedEntryIds.remove(entry.id);
                  } else {
                    _selectedEntryIds.add(entry.id);
                  }
                });
              }
            },
            child: Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              elevation: 0,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                  : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: isSelected
                    ? BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      )
                    : BorderSide.none,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isSelecting) ...[
                          Checkbox(
                            value: isSelected,
                            onChanged: (value) {
                              setState(() {
                                if (value!) {
                                  _selectedEntryIds.add(entry.id);
                                } else {
                                  _selectedEntryIds.remove(entry.id);
                                }
                              });
                            },
                          ),
                          SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.prompt,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${entry.date.day}/${entry.date.month}/${entry.date.year} - ${entry.date.hour}:${entry.date.minute.toString().padLeft(2, '0')}",
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      entry.entry,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    
                    if (entry.imagePaths.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        height: 120,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            for (int i = 0; i < entry.imagePaths.length; i++)
                              GestureDetector(
                                onTap: _isSelecting
                                    ? null
                                    : () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return Dialog(
                                              backgroundColor: Colors.transparent,
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  ClipRRect(
                                                    borderRadius: BorderRadius.circular(8),
                                                    child: Image.file(
                                                      File(entry.imagePaths[i]),
                                                      fit: BoxFit.contain,
                                                      errorBuilder: (context, error, stackTrace) {
                                                        return Container(
                                                          width: double.infinity,
                                                          height: 400,
                                                          color: Colors.grey[300],
                                                          child: Icon(
                                                            Icons.image,
                                                            size: 100,
                                                            color: Colors.grey[700],
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(height: 16),
                                                  ElevatedButton(
                                                    child: Text('Close'),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Theme.of(context).colorScheme.secondary,
                                                      foregroundColor: Colors.white,
                                                    ),
                                                    onPressed: () => Navigator.pop(context),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        );
                                      },
                                child: Container(
                                  margin: const EdgeInsets.only(right: 10),
                                  width: 120,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                    border: Border.all(
                                      color: Theme.of(context).colorScheme.primary,
                                      width: 2,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.file(
                                      File(entry.imagePaths[i]),
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Center(
                                          child: Icon(
                                            Icons.image,
                                            size: 50,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  ),
),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        elevation: 0,
        centerTitle: true,
        title: Text(
                'Journal Prompts',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.list_alt,
              color: Theme.of(context).colorScheme.onBackground,
            ),
            onPressed: () => setState(() => _showAllEntries = true),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      if (_showSwipeIndicator) {
                        setState(() {
                          _showSwipeIndicator = false;
                        });
                      }
                    },
                    itemCount: _currentPrompts.length,
                    itemBuilder: (context, index) {
                      final prompt = _currentPrompts[index];
                      return GestureDetector(
                        onTap: () => _showPromptBottomSheet(prompt),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: EdgeInsets.all(_currentPage == index ? 20 : 40),
                          decoration: BoxDecoration(
                            color: _currentPage == index 
                                ? Theme.of(context).colorScheme.primary 
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        prompt,
                                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                          color: Theme.of(context).colorScheme.onBackground,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 32),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.secondary,
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                        child: const Text(
                                          'Write Entry',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 16,
                                right: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12, 
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.secondary,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    (_promptCounts[prompt]==1)?"${_promptCounts[prompt] ?? 0} entry":"${_promptCounts[prompt] ?? 0} entries",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _isGeneratingPrompts ? null : () {
                      setState(() {
                        _isGeneratingPrompts = true;
                      });
                      
                      try {
                        Future.microtask(() {
                          _generateRandomPrompts();
                        }).whenComplete(() {
                          if (mounted) {
                            setState(() {
                              _isGeneratingPrompts = false;
                            });
                          }
                        });
                      } catch (e) {
                        setState(() {
                          _isGeneratingPrompts = false;
                        });
                        print('Error refreshing prompts: $e');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    icon: _isGeneratingPrompts 
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(Icons.refresh),
                    label: Text(_isGeneratingPrompts ? 'Refreshing...' : 'Refresh'),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
            if (_showSwipeIndicator)
              Positioned(
                right: 20,
                top: 0,
                bottom: 0,
                child: Center(
                  child: AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(_animation.value,0),
                          child: child,
                        );
                      },
                      child: AnimatedOpacity(
                        opacity: 1.0,
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
                            Icons.keyboard_arrow_right,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showImagePickerOptions(StateSetter setBottomSheetState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add Images',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImagePickerOption(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () => _pickImage(ImageSource.gallery, setBottomSheetState, multiple: true),
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  _buildImagePickerOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () => _pickImage(ImageSource.camera, setBottomSheetState),
                    color: Theme.of(context).colorScheme.secondary, 
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_selectedImages.isNotEmpty)
                TextButton(
                  onPressed: () {
                    setBottomSheetState(() {
                      _selectedImages = [];
                    });
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Remove All Images',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImagePickerOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(
              icon,
              size: 35,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
        ],
      ),
    );
  }
  
  void _showFullImage(int index, StateSetter setBottomSheetState) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _useMockImages
                  ? Container(
                      width: double.infinity,
                      height: 400,
                      color: Colors.grey[300],
                      child: Icon(
                        Icons.image,
                        size: 100,
                        color: Colors.grey[700],
                      ),
                    )
                  : Image.file(
                      File(_selectedImages[index].path),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          height: 400,
                          color: Colors.grey[300],
                          child: Icon(
                            Icons.image,
                            size: 100,
                            color: Colors.grey[700],
                          ),
                        );
                      },
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: Icon(Icons.delete, color: Colors.white),
                    label: Text('Remove'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      _removeImage(index, setBottomSheetState);
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    child: Text('Close'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _removeImage(int index, StateSetter setBottomSheetState) {
    setBottomSheetState(() {
      _selectedImages.removeAt(index);
    });
  }
}
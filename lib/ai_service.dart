import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as userBox;
import 'package:woke/question_hive.dart';

class AiService {
  static const String _baseUrl = 'https://api.mistral.ai/v1/chat/completions';
  

  static String? get _apiKey => dotenv.env['MISTRAL_API_KEY'];
  

  static GrowthAnalysis? _cachedAnalysis;
  static String? _cacheSignature;
  

  static String? _cachedUsername;
  

  static String _getUsername() {
    if (_cachedUsername != null) return _cachedUsername!;
    
    try {
      final box = Hive.box('userBox');
      final userData = box.get('userData');
      
      if (userData == null) {
        _cachedUsername = 'User'; 
        return _cachedUsername!;
      }
      
      String? name;
      if (userData is Map) {
        name = userData['name'];
      } else {

        name = userData.name;
      }
      
      _cachedUsername = name ?? 'User'; 
      return _cachedUsername!;
    } catch (e) {
      debugPrint('Error getting username: $e');
      _cachedUsername = 'User';
      return _cachedUsername!;
    }
  }
  
  
  static void clearUsernameCache() {
    _cachedUsername = null;
  }
  

  static Future<void> _initializeCache() async {

    if (_cacheInitialized) return;
    
    try {
      final cacheBox = await Hive.openBox('analysisCache');
      final cachedData = cacheBox.get('cachedAnalysis');
      final signature = cacheBox.get('cacheSignature');
      
      if (cachedData != null && signature != null) {
        _cachedAnalysis = GrowthAnalysis(
          summary: cachedData['summary'] ?? '',
          insights: List<String>.from(cachedData['insights'] ?? []),
          categories: Map<String, double>.from(cachedData['categories'] ?? {}),
        );
        _cacheSignature = signature;
        debugPrint('Loaded cached analysis from persistent storage');
      }
    } catch (e) {
      debugPrint('Error initializing cache: $e');
    }
    
    _cacheInitialized = true;
  }
  

  static bool _cacheInitialized = false;
  

  static Future<GrowthAnalysis> analyzeUserProgress() async {

    await _initializeCache();
    
    if (_apiKey == null || _apiKey!.isEmpty) {
      debugPrint('Mistral AI API key not found in .env file');
      return GrowthAnalysis(
        summary: 'Analysis not available - API key missing',
        insights: [],
        categories: {},
      );
    }
    

    final allAnswers = await _getAllAnswers();
    
    if (allAnswers.isEmpty) {
      return GrowthAnalysis(
        summary: 'Not enough data to analyze yet. Keep answering daily questions!',
        insights: [],
        categories: {},
      );
    }
    

    final currentSignature = _generateDataSignature(allAnswers);
    

    if (_cachedAnalysis != null && _cacheSignature == currentSignature) {
      debugPrint('Using cached growth analysis');
      return _cachedAnalysis!;
    }
    

    debugPrint('Generating new growth analysis');
    

    final prompt = _generatePrompt(allAnswers);
    final username = _getUsername();
    
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          "model": "mistral-large-latest",
          "messages": [
            {
              "role": "system",
              "content": "You are an AI assistant that analyzes journal entries and question responses to provide insightful observations about a person's growth, patterns, and emotional journey. Focus on identifying themes, changes in perspective, and notable trends. The user's name is $username."
            },
            {
              "role": "user",
              "content": prompt
            }
          ],
          "temperature": 0.7,
          "max_tokens": 1024
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final analysisText = data['choices'][0]['message']['content'];
        

        final analysis = _parseAnalysisResponse(analysisText);
        _cachedAnalysis = analysis;
        _cacheSignature = currentSignature;
        

        await _saveAnalysisCache(analysis, currentSignature);
        
        return analysis;
      } else {
        debugPrint('Error from Mistral AI: ${response.body}');
        

        if (_cachedAnalysis != null) {
          debugPrint('Using previous cached analysis due to API error');
          return _cachedAnalysis!;
        }
        

        final loadedCache = await _loadAnalysisCache();
        if (loadedCache != null) {
          debugPrint('Using persistent cached analysis due to API error');
          _cachedAnalysis = loadedCache;
          return loadedCache;
        }
        
        return GrowthAnalysis(
          summary: 'Unable to generate analysis at this time. Please try again later.',
          insights: [],
          categories: {},
        );
      }
    } catch (e) {
      debugPrint('Exception during AI analysis: $e');
      

      if (_cachedAnalysis != null) {
        debugPrint('Using previous cached analysis due to exception');
        return _cachedAnalysis!;
      }
      

      final loadedCache = await _loadAnalysisCache();
      if (loadedCache != null) {
        debugPrint('Using persistent cached analysis due to exception');
        _cachedAnalysis = loadedCache;
        return loadedCache;
      }
      
      return GrowthAnalysis(
        summary: 'Analysis failed due to a technical issue. Please try again later.',
        insights: [],
        categories: {},
      );
    }
  }

  static Future<String> getGrowthFactoid() async {
    try {

      final allAnswers = await _getAllAnswers();
      
      if (allAnswers.isEmpty) {

        const fallbackMessages = [
          "Start answering questions to unlock personalized insights!",
          "Your first answer will begin your growth journey",
          "Reflect on your day to discover meaningful patterns"
        ];
        final randomIndex = DateTime.now().millisecond % fallbackMessages.length;
        return fallbackMessages[randomIndex];
      }

      if (_apiKey == null || _apiKey!.isEmpty) {
        return "Complete your daily reflection to see insights";
      }

      final username = _getUsername();


      final prompt = '''
Analyze these Q&A pairs and generate 5 concise notifications (max 80 characters each) that:
1. Highlight recurring themes
2. Show positive changes
3. Point out patterns
4. Are uplifting
5. Reference my content when possible
6. USE NO MARKDOWN (no **, __, etc.) AND NO QUOTES
7. MAX 80 CHARACTERS PER NOTIFICATION

Examples:
- You've mentioned travel in 5 answers recently
- Becoming more optimistic based on your answers
- Self-confidence growing in recent reflections

Format response with each notification on a new line starting with "-"

My answers:
${allAnswers.take(20).map((a) => 
  "Q: ${a.question}\nA: ${a.answer}\nDate: ${a.date.toString().substring(0, 10)}\n"
).join('\n')}
''';

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          "model": "mistral-large-latest",
          "messages": [
            {
              "role": "system",
              "content": "Generate clean notifications (no markdown, no quotes, max 80 chars) based on journal patterns for $username."
            },
            {
              "role": "user",
              "content": prompt
            }
          ],
          "temperature": 0.7,
          "max_tokens": 256
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final notificationsText = data['choices'][0]['message']['content'];
        

        final notifications = notificationsText
            .split('\n')
            .where((String line) => line.trim().startsWith('-'))
            .map((String line) => _cleanNotification(line.replaceFirst('-', '').trim()))
            .where((String notification) => notification.isNotEmpty)
            .toList();
        
        if (notifications.isNotEmpty) {

          final randomIndex = DateTime.now().millisecond % notifications.length;
          return _truncateToMaxLength(notifications[randomIndex]);
        }
      }
      
      return "Your reflections reveal interesting patterns";
    } catch (e) {
      debugPrint('Exception while creating growth factoid: $e');
      return "New insights available from your reflections";
    }
  }


  static String _cleanNotification(String text) {
    String cleaned = text.replaceAll(RegExp(r'\*\*|__'), ''); 
    cleaned = cleaned.replaceAll('"', ''); 
    return cleaned.trim();
  }


  static String _truncateToMaxLength(String text) {
    const maxLength = 100;
    if (text.length <= maxLength) return text;
    

    final lastPeriod = text.lastIndexOf('.', maxLength - 1);
    if (lastPeriod > 0) return text.substring(0, lastPeriod + 1);
    

    final lastSpace = text.lastIndexOf(' ', maxLength - 4);
    if (lastSpace > 0) return '${text.substring(0, lastSpace)}...';
    

    return '${text.substring(0, maxLength - 3)}...';
  }


  static String _truncateForNotification(String text) {
    const maxLength = 100;
    if (text.length <= maxLength) return text;
    

    final sentenceMatch = RegExp(r'(.+?[.!?])').firstMatch(text);
    if (sentenceMatch != null) {
      final firstSentence = sentenceMatch.group(1) ?? '';
      if (firstSentence.length <= maxLength) return firstSentence;
    }
    

    return '${text.substring(0, maxLength - 3)}...';
  }
  

  static String _generateDataSignature(List<AnswerData> answers) {

    answers.sort((a, b) => a.date.compareTo(b.date));
    

    final signatureParts = answers.map((answer) => 
      '${answer.date.toIso8601String()}|${answer.question}|${answer.answer}'
    ).toList();
    

    return '${answers.length}:${signatureParts.join('###')}';
  }
  

  static Future<void> _saveAnalysisCache(GrowthAnalysis analysis, String signature) async {
    try {
      final cacheBox = await Hive.openBox('analysisCache');
      await cacheBox.put('cachedAnalysis', analysis.toJson());
      await cacheBox.put('cacheSignature', signature);
      await cacheBox.put('timestamp', DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Error saving analysis cache: $e');
    }
  }
  

  static Future<GrowthAnalysis?> _loadAnalysisCache() async {
    try {

      await _initializeCache();
      

      if (_cachedAnalysis != null) {
        return _cachedAnalysis;
      }
      

      final cacheBox = await Hive.openBox('analysisCache');
      final cachedData = cacheBox.get('cachedAnalysis');
      final signature = cacheBox.get('cacheSignature');
      
      if (cachedData != null && signature != null) {

        _cacheSignature = signature;
        final analysis = GrowthAnalysis(
          summary: cachedData['summary'] ?? '',
          insights: List<String>.from(cachedData['insights'] ?? []),
          categories: Map<String, double>.from(cachedData['categories'] ?? {}),
        );
        _cachedAnalysis = analysis;
        return analysis;
      }
    } catch (e) {
      debugPrint('Error loading analysis cache: $e');
    }
    return null;
  }
  

  static Future<void> clearAnalysisCache() async {
    _cachedAnalysis = null;
    _cacheSignature = null;
    _cacheInitialized = false;
    try {
      final cacheBox = await Hive.openBox('analysisCache');
      await cacheBox.clear();
    } catch (e) {
      debugPrint('Error clearing analysis cache: $e');
    }
  }
  

  static Future<List<AnswerData>> _getAllAnswers() async {
    final answersBox = Hive.box('questionAnswers');
    final allAnswerKeys = answersBox.keys.where((key) => 
      key.toString().startsWith('day_') || key == 'leapDay').toList();
    
    List<AnswerData> allAnswers = [];
    
    for (var key in allAnswerKeys) {
      final answers = answersBox.get(key) ?? [];
      
      for (var answer in answers) {
        try {
          if (answer is Map) {
            final qa = QuestionAnswer.fromJson(Map<String, dynamic>.from(answer));
            allAnswers.add(AnswerData(
              date: qa.dateAnswered,
              question: qa.question,
              answer: qa.answer,
            ));
          }
        } catch (e) {
          debugPrint('Error parsing answer: $e');
        }
      }
    }
    

    allAnswers.sort((a, b) => b.date.compareTo(a.date));
    
    return allAnswers;
  }


  static Future<String> compareAnswers(String currentAnswer, String previousAnswer, String question, DateTime currentDate, DateTime previousDate) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      return 'Cannot compare answers - API key missing';
    }
    
    final username = _getUsername();
    
    try {
      final prompt = '''
Compare these two answers to the same question that were given on different dates:

Question: $question

Answer on ${previousDate.year}-${previousDate.month.toString().padLeft(2, '0')}-${previousDate.day.toString().padLeft(2, '0')}:
$previousAnswer

Answer on ${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}:
$currentAnswer

In 2-3 concise sentences, describe how the person's perspective, feelings, or thoughts have changed between these answers. Focus on growth, changes in mindset, or shifting priorities. Be precise and tell how much the person has grown or not grown, and in which way or perspective.
(STRICTLY DO NOT USE ANY MARKDOWN, DOUBLE QUOTES, ASTERISKS OR OTHER FORMATTING.)
''';

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          "model": "mistral-large-latest",
          "messages": [
            {
              "role": "system",
              "content": "You are an insightful assistant that analyzes how my perspectives change over time. Provide brief, meaningful comparisons that highlight personal growth, shifts in thinking, or new insights for me, and my name is $username. Talk to me in second person."
            },
            {
              "role": "user",
              "content": prompt
            }
          ],
          "temperature": 0.7,
          "max_tokens": 256
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final analysis = data['choices'][0]['message']['content'];
        return analysis.trim();
      } else {
        debugPrint('Error from Mistral AI: ${response.body}');
        return 'Unable to compare answers at this time.';
      }
    } catch (e) {
      debugPrint('Exception during answer comparison: $e');
      return 'Could not generate comparison due to a technical issue.';
    }
  }
  

  static String _generatePrompt(List<AnswerData> answers) {

    answers.sort((a, b) => a.date.compareTo(b.date));
    
    final buffer = StringBuffer();
    buffer.writeln('Please analyze the following answers of mine, which I gave to self-awareness questions, and provide:');
    buffer.writeln('1. A short summary of growth or changes observed (2-3 sentences)');
    buffer.writeln('2. 3-5 specific insights about patterns, themes, or changes in perspective');
    buffer.writeln('3. Categorize entries by themes (e.g., relationships, career, personal growth)');
    buffer.writeln('\nFormat your response like this:');
    buffer.writeln('SUMMARY: [Your 2-3 sentence summary]');
    buffer.writeln('INSIGHTS:');
    buffer.writeln('- [First insight]');
    buffer.writeln('- [Second insight]');
    buffer.writeln('CATEGORIES:');
    buffer.writeln('Theme1: [percentage]');
    buffer.writeln('Theme2: [percentage]');
    buffer.writeln('\nHere are the entries:');
    
    int entryNumber = 1;
    for (var entry in answers) {
      final formattedDate = '${entry.date.year}-${entry.date.month.toString().padLeft(2, '0')}-${entry.date.day.toString().padLeft(2, '0')}';
      buffer.writeln('\nEntry $entryNumber - $formattedDate');
      buffer.writeln('Q: ${entry.question}');
      buffer.writeln('A: ${entry.answer}');
      entryNumber++;
    }
    
    return buffer.toString();
  }
  

  static GrowthAnalysis _parseAnalysisResponse(String response) {
    String summary = '';
    List<String> insights = [];
    Map<String, double> categories = {};
    

    final summaryMatch = RegExp(r'SUMMARY:\s*(.+?)(?=INSIGHTS:|$)', dotAll: true).firstMatch(response);
    if (summaryMatch != null) {
      summary = summaryMatch.group(1)?.trim() ?? '';

      summary = _removeFormattingCharacters(summary);
    }
    

    final insightsSection = RegExp(r'INSIGHTS:(.*?)(?=CATEGORIES:|$)', dotAll: true).firstMatch(response);
    if (insightsSection != null) {
      final insightsText = insightsSection.group(1) ?? '';
      insights = insightsText
          .split('\n')
          .where((line) => line.trim().startsWith('-'))
          .map((line) => line.replaceFirst('-', '').trim())
          .where((insight) => insight.isNotEmpty)
          .toList();
    }
    

    final categoriesSection = RegExp(r'CATEGORIES:(.*?)$', dotAll: true).firstMatch(response);
    if (categoriesSection != null) {
      final categoriesText = categoriesSection.group(1) ?? '';
      final categoryLines = categoriesText
          .split('\n')
          .where((line) => line.trim().isNotEmpty && line.contains(':'))
          .toList();
      
      for (var line in categoryLines) {
        final parts = line.split(':');
        if (parts.length == 2) {

          final categoryName = _removeFormattingCharacters(parts[0].trim());
          final percentageText = parts[1].trim().replaceAll('%', '');
          
          try {
            final percentage = double.parse(percentageText);
            categories[categoryName] = percentage;
          } catch (e) {

            categories[categoryName] = 0;
          }
        }
      }
    }
    
    return GrowthAnalysis(
      summary: summary,
      insights: insights,
      categories: categories,
    );
  }


  static String _removeFormattingCharacters(String text) {

    String result = text.replaceAll('*', '');
    

    result = result.replaceAll('"', '');
    

    if (result.startsWith('-')) {
      result = result.replaceFirst('-', '').trim();
    }
    
    return result;
  }
}


class AnswerData {
  final DateTime date;
  final String question;
  final String answer;
  
  AnswerData({
    required this.date,
    required this.question,
    required this.answer,
  });
}

class GrowthAnalysis {
  final String summary;
  final List<String> insights;
  final Map<String, double> categories;

  Map<String, dynamic> toJson() {
    return {
      'summary': summary,
      'insights': insights,
      'categories': categories,
    };
  }
  
  GrowthAnalysis({
    required this.summary,
    required this.insights,
    required this.categories,
  });
}
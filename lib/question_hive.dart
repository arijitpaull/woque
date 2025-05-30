import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';


class QuestionAnswer {
  final String question;
  final String answer;
  final DateTime dateAnswered;

  QuestionAnswer({
    required this.question,
    required this.answer,
    required this.dateAnswered,
  });

  
  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'answer': answer,
      'dateAnswered': dateAnswered.millisecondsSinceEpoch,
    };
  }

  factory QuestionAnswer.fromJson(Map<String, dynamic> json) {
    return QuestionAnswer(
      question: json['question'] as String,
      answer: json['answer'] as String,
      dateAnswered: DateTime.fromMillisecondsSinceEpoch(json['dateAnswered'] as int),
    );
  }
}


Future<void> initQuestionHive() async {
  await Hive.initFlutter();
  await Hive.openBox('questionAnswers'); 
  await Hive.openBox('questions');
  
  
  await _initializeQuestions();
}


Future<String> getTodaysQuestion() async {
  final questionsBox = Hive.box('questions');
  final questions = questionsBox.get('allQuestions') ?? [];
  
  if (questions.isEmpty) {
    throw Exception("Questions not initialized");
  }
  
  
  final now = DateTime.now();
  final dayOfYear = _getDayOfYear(now);
  
  
  int questionIndex = dayOfYear - 1;
  if (_isLeapDay(now)) {
    
    return "What special thing did you do for this leap day?";
  }
  
  
  if (_isLeapYear(now.year) && now.month > 2) {
    questionIndex--;
  }
  
  
  questionIndex = (questionIndex % questions.length).toInt();
  
  return questions[questionIndex];
}


Future<String?> getAnswerForToday() async {
  final today = DateTime.now();
  final questionKey = _getQuestionKey(today);
  
  final answersBox = Hive.box('questionAnswers');
  final rawAnswers = answersBox.get(questionKey);
  
  if (rawAnswers == null) return null;
  
  List<QuestionAnswer> answers = [];
  if (rawAnswers is List) {
    answers = rawAnswers.map((raw) {
      if (raw is Map) {
        return QuestionAnswer.fromJson(Map<String, dynamic>.from(raw));
      }
      return null;
    }).whereType<QuestionAnswer>().toList();
  }
  
  
  final currentYearAnswer = answers.where((qa) => 
    qa.dateAnswered.year == today.year &&
    _isSameDay(qa.dateAnswered, today)
  ).firstOrNull;
  
  return currentYearAnswer?.answer;
}


Future<void> saveAnswerForToday(String answer) async {
  final today = DateTime.now();
  final questionKey = _getQuestionKey(today);
  final question = await getTodaysQuestion();
  
  final answersBox = Hive.box('questionAnswers');
  final rawAnswers = answersBox.get(questionKey) ?? [];
  
  List<Map<String, dynamic>> serializedAnswers = [];
  if (rawAnswers is List) {
    serializedAnswers = rawAnswers.map((raw) {
      if (raw is Map) {
        return Map<String, dynamic>.from(raw);
      }
      return null;
    }).whereType<Map<String, dynamic>>().toList();
  }
  
  
  List<QuestionAnswer> answers = serializedAnswers.map((json) => 
    QuestionAnswer.fromJson(json)).toList();
  
  
  final index = answers.indexWhere((qa) => 
    qa.dateAnswered.year == today.year &&
    _isSameDay(qa.dateAnswered, today)
  );
  
  final newAnswer = QuestionAnswer(
    question: question,
    answer: answer,
    dateAnswered: today,
  );
  
  if (index >= 0) {
    
    answers[index] = newAnswer;
  } else {
    
    answers.add(newAnswer);
  }
  
  
  final serializedList = answers.map((qa) => qa.toJson()).toList();
  await answersBox.put(questionKey, serializedList);
}


Future<List<QuestionAnswer>> getPreviousAnswers() async {
  final today = DateTime.now();
  final questionKey = _getQuestionKey(today);
  
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
  
  
  answers.sort((a, b) => b.dateAnswered.compareTo(a.dateAnswered));
  
  
  return answers.where((qa) => 
    qa.dateAnswered.year != today.year && 
    _getDayOfYear(qa.dateAnswered) == _getDayOfYear(today)
  ).toList();
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


bool _isLeapYear(int year) {
  return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
}


bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}


Future<void> _initializeQuestions() async {
  final questionsBox = Hive.box('questions');
  
  
  if (questionsBox.get('allQuestions') != null) {
    return;
  }
  
  
  final List<String> questions = [
  "What are you most grateful for in your life right now?", 
  "What personal quality would you most like to improve?", 
  "What does success mean to you today?", 
  "What is your biggest fear, and has it changed recently?", 
  "Describe your perfect day from start to finish.", 
  "What relationship in your life needs the most attention right now?", 
  "What hobby or activity makes you lose track of time?", 
  "What would you do differently if nobody would judge you?", 
  "What's one small thing that brought you joy today?", 
  "What challenge are you currently facing that's helping you grow?", 
  "What's something you believe that most people around you don't?", 
  "What do you need more of in your life?", 
  "What do you need less of in your life?", 
  "What mistake have you made that taught you something valuable?", 
  "What's one thing about yourself that you hope never changes?", 
  "What's the most beautiful place you've ever been?", 
  "Who has influenced your life the most, and how?", 
  "What does self-care look like for you right now?", 
  "What boundaries do you need to establish or maintain?", 
  "What's something you've changed your mind about recently?", 
  "If you could master one skill instantly, what would it be?", 
  "What does home mean to you?", 
  "What's the kindest thing someone has done for you recently?", 
  "What's the kindest thing you've done for someone else recently?", 
  "When do you feel most like yourself?", 
  "What's your relationship with social media like right now?", 
  "What are you avoiding that you know you should address?", 
  "What are you looking forward to in the coming months?", 
  "What would your younger self think of who you are today?", 
  "What lesson has taken you the longest to learn?", 
  "What brings you comfort when you're stressed or upset?", 
  "What are three qualities you value most in others?", 
  "What are three of your personal strengths?", 
  "What do you know to be true that you didn't know a year ago?", 
  "What small habit has had the biggest positive impact on your life?", 
  "What's your earliest memory?", 
  "What does your ideal work environment look like?", 
  "What part of your daily routine do you most enjoy?", 
  "What's a belief you had as a child that you no longer hold?", 
  "What would you do if you knew you couldn't fail?", 
  "How have your priorities changed over the past few years?", 
  "What legacy would you like to leave behind?", 
  "What do you value most: time, energy, attention, or money?", 
  "What's something difficult you're willing to practice because you care about it?", 
  "When did you last feel truly at peace?", 
  "What does wealth mean to you?", 
  "How do you define love?", 
  "What are you currently learning about yourself?", 
  "What is your body trying to tell you today?", 
  "What childhood experience has shaped who you are today?", 
  "What's the most valuable thing you own that isn't worth much money?", 
  "What makes a good friend?", 
  "What problem do you wish you could solve?", 
  "What achievement are you most proud of?", 
  "How do you handle criticism?", 
  "What are you currently overthinking?", 
  "When was the last time you tried something completely new?", 
  "What book, movie, or song has influenced you the most?", 
  "What's the best advice you've ever received?", 
  "What's the best advice you've ever given?", 
  "What's something you wish more people understood about you?", 
  "How do you want to be remembered?", 
  "What brings you hope during difficult times?", 
  "What are you currently procrastinating on?", 
  "What do you wish you had more time for?", 
  "How would you describe your current life phase?", 
  "What's your relationship with food like?", 
  "How do you define happiness?", 
  "What have you let go of that once seemed important?", 
  "What would your ideal living space look like?", 
  "What emotion is most difficult for you to express?", 
  "What emotion is easiest for you to express?", 
  "What do you need right now that you're not getting?", 
  "What's a compliment you recently received that meant a lot to you?", 
  "What personal rule or principle do you never break?", 
  "What are you most curious about right now?", 
  "What feels like home to you?", 
  "What's your favorite way to spend time alone?", 
  "What's your favorite way to connect with others?", 
  "How have your political or social views evolved over time?", 
  "What's something you wish you'd learned earlier in life?", 
  "What area of your health deserves more attention?", 
  "What are your current non-negotiables in life?", 
  "What are your thoughts on spirituality today?", 
  "What are you most committed to in your life right now?", 
  "What's the most spontaneous thing you've done recently?", 
  "What's your relationship with your past like?", 
  "What do you hope for your future?", 
  "What's your biggest strength as a communicator?", 
  "What's your biggest challenge as a communicator?", 
  "What are you currently saving for?", 
  "What's your definition of a life well-lived?", 
  "What brings meaning to your work?", 
  "What's a cultural or societal norm you disagree with?", 
  "What's one thing you'd like to be known for?", 
  "What are your thoughts on aging?", 
  "What's your relationship with technology like?", 
  "What's your biggest time waster?", 
  "What would you not give up for a million dollars?", 
  "What have you changed your mind about in the last year?", 
  "How do you respond to conflict?", 
  "What's something you'd like to revive from your past?", 
  "What are your current values, and have they changed?", 
  "What's a risk you're glad you took?", 
  "What's a risk you regret not taking?", 
  "What's one thing that always makes you laugh?", 
  "What's currently causing you stress?", 
  "What's your relationship with sleep like right now?", 
  "What makes you feel most alive?", 
  "What's a dream you've had that you'd like to revisit?", 
  "What in your life feels heavy right now?", 
  "What in your life feels light right now?", 
  "What's something you've been putting off dealing with?", 
  "What are you most passionate about?", 
  "What feels just out of reach for you right now?", 
  "What's something you've achieved that once seemed impossible?", 
  "What's a small everyday pleasure you're grateful for?", 
  "What tradition or ritual is important to you?", 
  "What's something you're ambivalent about?", 
  "What's a decision you're currently struggling with?", 
  "What's one thing you're willing to suffer for?", 
  "What's your relationship with money like right now?", 
  "What does your inner critic tell you most often?", 
  "When do you feel most creative?", 
  "What's something you've outgrown?", 
  "What are you currently overcommitted to?", 
  "What's something you refused to give up on?", 
  "What's a question you're trying to answer in your life right now?", 
  "What's something challenging you've recently come to appreciate?", 
  "What's something you like about your current age?", 
  "What are you grieving right now?", 
  "What makes you feel understood?", 
  "What are you striving for?", 
  "What in your life currently feels chaotic?", 
  "What in your life feels stable?", 
  "What's a hard truth you've had to accept?", 
  "What's something unexpected that brought you joy recently?", 
  "What are you currently making peace with?", 
  "What are your favorite qualities about yourself?", 
  "What have you been taking for granted that you want to appreciate more?", 
  "What's something you're ready to let go of?", 
  "What's something you'd like to welcome into your life?", 
  "What's something you stand for?", 
  "What's something you stand against?", 
  "What's a rule you live by?", 
  "What are your thoughts on love today?", 
  "What's something you're still figuring out?", 
  "What role does nature play in your life?", 
  "What's your relationship with your body like right now?", 
  "What truth about yourself are you avoiding?", 
  "What does freedom mean to you?", 
  "What's the most important lesson life has taught you?", 
  "What's a current personal contradiction you're working through?", 
  "What would make tomorrow great?", 
  "What is your definition of enough?", 
  "What's the difference between who you are and who you want to be?", 
  "What part of yourself do you try to hide from others?", 
  "What's a secret talent or skill you have?", 
  "What does respect mean to you?", 
  "What feels like a luxury to you?", 
  "What makes you feel powerful?", 
  "What makes you feel vulnerable?", 
  "What makes a place feel like home to you?", 
  "What's an uncomfortable truth you've come to accept?", 
  "What's something you're no longer willing to tolerate?", 
  "What are you trying to prove right now, and to whom?", 
  "What's something that feels heavy but is actually serving you?", 
  "What would you do if you had more courage?", 
  "What's a meaningful coincidence you've experienced?", 
  "What topic can you talk about for hours?", 
  "What aspect of your identity feels most important to you?", 
  "What's a value you won't compromise on?", 
  "What's something that feels true but you can't prove?", 
  "What's something you believe that few others seem to?", 
  "What's the most challenging feedback you've received?", 
  "What's a new habit you're trying to establish?", 
  "What's an old habit you're trying to break?", 
  "What makes you lose track of time?", 
  "What do you turn to when you need comfort?", 
  "What energizes you when you feel depleted?", 
  "What's holding you back right now?", 
  "What's propelling you forward?", 
  "What responsibility do you wish you didn't have?", 
  "What responsibility are you grateful to have?", 
  "What's a choice you're glad you made?", 
  "What's a simple pleasure you never tire of?", 
  "What's your relationship with your hometown like?", 
  "What's something you know you need to address but haven't yet?", 
  "What's a personal rule you've broken recently?", 
  "What's something you're reluctant to tell others?", 
  "What are you currently healing from?", 
  "What's a recurring dream or thought you have?", 
  "What's something you're excited about right now?", 
  "What's something you'd like to experiment with?", 
  "How do you want to grow in the coming year?", 
  "What's a piece of your past that you're still making sense of?", 
  "What's something you've been meaning to try?", 
  "What's a quality you admire in others but don't see in yourself?", 
  "What's a quality you have that others admire?", 
  "What's something that restores your faith in humanity?", 
  "What's a personal mystery you'd like to solve?", 
  "What's something you deeply appreciate about your life right now?", 
  "What's a core belief that shapes many of your decisions?", 
  "What's something you've been consistent about?", 
  "What's something you struggle to be consistent with?", 
  "What's a difficult conversation you need to have?", 
  "What's something you're ready to forgive?", 
  "What matters less to you now than it did a year ago?", 
  "What matters more to you now than it did a year ago?", 
  "What's your most prized possession and why?", 
  "What part of your daily routine needs reimagining?", 
  "What's something you'd like to stop overthinking?", 
  "What choice are you facing that you wish someone would make for you?", 
  "What's a skill you've recently improved?", 
  "What's something you're currently reconciling in your life?", 
  "What do you need to say no to?", 
  "What do you need to say yes to?", 
  "What's something you're questioning right now?", 
  "What's something you've recently become certain about?", 
  "What's a challenge you're proud of overcoming?", 
  "What's a small act of rebellion in your life?", 
  "What's something you're hesitant to share with others?", 
  "What's something you wish people would ask you about?", 
  "What's a topic you recently changed your mind about?", 
  "What aspect of your future makes you anxious?", 
  "What aspect of your future excites you?", 
  "What makes you feel seen?", 
  "What currently feels like a burden to you?", 
  "What currently feels like a blessing to you?", 
  "What role does creativity play in your life?", 
  "What's a limitation that you're working with right now?", 
  "What's a strength you rely on regularly?", 
  "What's something beautiful you've noticed recently?", 
  "What's a question you don't have the answer to yet?", 
  "What's a boundary you need to establish or reinforce?", 
  "What's a recent realization about yourself?", 
  "What are your thoughts on compromise?", 
  "What's something no one can take away from you?", 
  "What motivates you to get out of bed in the morning?", 
  "What calms you down when you're upset?", 
  "What do you consider to be your purpose right now?", 
  "What are you putting off until the 'right time'?", 
  "What's something you recently outgrew?", 
  "What's a habit that currently serves you well?", 
  "What makes you feel truly alive?", 
  "What grounds you when you feel anxious or overwhelmed?", 
  "What's something you've overcome that once seemed impossible?", 
  "What parts of your identity have remained consistent throughout your life?", 
  "What parts of your identity have changed dramatically?", 
  "What has been your most courageous moment so far?", 
  "What's something you're clinging to that you need to release?", 
  "What's something you need to start saying no to?", 
  "What's something you need to start saying yes to?", 
  "What's a dream you've put aside?", 
  "What pain are you currently facing that might actually be serving your growth?", 
  "What's something you hope to understand better by this time next year?", 
  "What are you trying to maintain control over that you probably should let go of?", 
  "What's a small change you could make today that would benefit your future?", 
  "What's something others see in you that you have trouble seeing in yourself?", 
  "What have you been neglecting that requires your attention?", 
  "What does inner peace look like to you?", 
  "What's something you're learning to accept about yourself?", 
  "What does it mean to you to live authentically?", 
  "What truth are you hiding from?", 
  "What's something you're afraid to hope for?", 
  "What's your current relationship with uncertainty?", 
  "What are you willing to struggle for?", 
  "What's a question that keeps recurring in your life?", 
  "What's been occupying your thoughts lately?", 
  "What message do you need to hear right now?", 
  "What do you need to forgive yourself for?", 
  "What assumptions about life have you had to revise?", 
  "What desire feels most true to you right now?", 
  "What does rest mean to you at this point in your life?", 
  "What makes time feel well-spent to you?", 
  "What's something you'd like to unlearn?", 
  "What contradiction do you live with?", 
  "What truth about yourself are you avoiding?", 
  "What's something you've been meaning to create?", 
  "What's a change you've made that has improved your life?", 
  "What would you attempt if you knew you had support?", 
  "What's something you've been afraid to start?", 
  "What's a burden you're carrying that isn't yours to hold?", 
  "What's something about your current routine that feels life-giving?", 
  "What's something about your current routine that feels life-draining?", 
  "What's something you need to reclaim?", 
  "What experience has changed the way you see the world?", 
  "What breaks your heart?", 
  "What mends your heart?", 
  "What does 'balance' mean to you in this season of your life?", 
  "What's something that doesn't come naturally to you but you work at anyway?", 
  "What does courage look like for you today?", 
  "What would help you feel more at peace with your past?", 
  "What opportunity are you currently grateful for?", 
  "What will you not settle for in your life?", 
  "What do you aspire to embody more fully?", 
  "What are you currently doing that your future self will thank you for?", 
  "What are you currently doing that your future self might regret?", 
  "What does being gentle with yourself look like?", 
  "What's a loss you're still processing?", 
  "What's something you'd like to celebrate about yourself?", 
  "What advice would you give your past self from one year ago?", 
  "What are the hardest words you've had to say?", 
  "What brings you back to yourself when you feel lost?", 
  "What's something difficult you're proud of facing?", 
  "What's a challenging perspective you've been considering lately?", 
  "What do you know now that you wish you'd known sooner?", 
  "What's a limiting belief you're working to overcome?", 
  "What's a risk you wish you had taken?", 
  "What are you learning to live with?", 
  "What are you learning to live without?", 
  "What would it look like to be kinder to yourself today?", 
  "What's a mistake you keep making?", 
  "What's an insight about yourself you recently had?", 
  "What's a place, real or imagined, that brings you peace?", 
  "What version of yourself do you miss?", 
  "What version of yourself are you looking forward to becoming?", 
  "What relationship needs your attention right now?", 
  "What's a question you're afraid to ask because you might not like the answer?", 
  "What's something you've been meaning to tell someone?", 
  "What are you settling for?", 
  "What are you striving for?", 
  "What's something you know you need to prioritize?", 
  "What are you avoiding thinking about?", 
  "What feels like progress to you right now?", 
  "What feels like a step backward?", 
  "What do you want to invite more of into your life?", 
  "What do you want to release from your life?", 
  "What's a difficult truth you're currently facing?", 
  "What's a pleasant surprise that recently happened to you?", 
  "What's your relationship with change?", 
  "What's a pattern you want to break?", 
  "What would be different if you truly believed in yourself?", 
  "What's your relationship with silence?", 
  "What's something that once hurt you but now you're grateful for?", 
  "What's something you'd like to be remembered for?", 
  "What's a recurring thought that might be holding you back?", 
  "What's a conversation you need to have with yourself?", 
  "What vulnerability have you been avoiding?", 
  "What decision have you been postponing?", 
  "What's something you're ready to face?", 
  "What makes you feel most connected to others?", 
  "What are you willing to fight for?", 
  "What's a surprising way you've changed in the past year?", 
  "What lesson keeps appearing in your life?", 
  "What are you hopeful about right now?", 
  "What have you been taking too seriously?", 
  "What have you not been taking seriously enough?", 
  "What's a truth you need to tell yourself more often?", 
  "What's been your biggest internal struggle lately?", 
  "What do you wish you could let go of more easily?", 
  "What gives you a sense of belonging?", 
  "What's a question you wish someone would ask you?", 
  "What would your ideal day look like one year from now?", 
  "What expectations do you need to release?", 
  "What's something you believe now that you didn't believe a year ago?", 
  "What's something you no longer believe that you did a year ago?", 
  "What area of your life deserves more celebration?", 
  "What would you attempt if failure wasn't an option?", 
  "What are you ready to commit to?", 
  "What challenge are you currently embracing?", 
  "What's a hard lesson you're grateful to have learned?", 
  "What matters most to you at this stage in your life?", 
  "What would you like to be known for in the next chapter of your life?", 
  "If you could send a message to yourself one year from now, what would it say?", 
  ];
  
  
  while (questions.length < 365) {
    final dayNumber = questions.length + 1;
    questions.add("Reflection question #$dayNumber: What made you smile today?");
  }
  
  await questionsBox.put('allQuestions', questions);
}
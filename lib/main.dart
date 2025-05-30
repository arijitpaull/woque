import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:woke/app_lifecycle_handler.dart';
import 'package:woke/mood.dart';
import 'package:woke/notification_service.dart';
import 'package:woke/questions.dart';
import 'package:woke/journal.dart';
import 'package:woke/analytics.dart';
import 'package:woke/rewards_hive.dart';
import 'package:woke/settings.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:woke/question_hive.dart';
import 'package:woke/journal_hive.dart';
import 'package:woke/mood_hive.dart';
import 'package:woke/user_hive.dart';
import 'package:woke/walthrough_page.dart';
import 'package:flutter/services.dart';


class AppInitializer {
  static bool isInitialized = false;
  static bool isInitializing = false;
  
  
  static Future<void> initializeApp() async {
    if (isInitialized || isInitializing) return;
    
    isInitializing = true;
    
    try {
      
      await Hive.initFlutter();
      Hive.registerAdapter(UserDataAdapter());
      Hive.registerAdapter(RewardAdapter());
      
      
      await initUserHive();
      
      
      await Future.wait([
        initQuestionHive(),
        initJournalHive(),
        initMoodHive(),
        initRewardsHive(),
      ]);
      
      
      await dotenv.load(fileName: ".env").catchError((e) {
        debugPrint("Error loading .env file: $e");
        
      });
      
      
      final notificationService = NotificationService();
      await notificationService.initialize();
      await notificationService.scheduleAllNotifications();
      
      isInitialized = true;
    } catch (e) {
      debugPrint("Error during app initialization: $e");
      
      isInitialized = true; 
    }
    
    isInitializing = false;
  }
}

void main() async {
  
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  
  
  final lifecycleHandler = AppLifecycleHandler();
  WidgetsBinding.instance.addObserver(lifecycleHandler);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          background: const Color(0xFFF5F2EB), 
          onBackground: const Color(0xFF5D5348), 
          primary: const Color(0xFFE8DFD0), 
          secondary: const Color(0xFFBCAD99), 
          tertiary: const Color(0xFF8C7A6B), 
        ),
        textTheme: TextTheme(
          headlineSmall: TextStyle(
            color: const Color(0xFF5D5348),
            fontWeight: FontWeight.w500,
          ),
          bodyLarge: TextStyle(
            color: const Color(0xFF5D5348),
          ),
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), 
    );
    
    
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    
    
    _animationController.forward();
    
    
    _initializeAppAndNavigate();
  }

  Future<void> _initializeAppAndNavigate() async {
    
    AppInitializer.initializeApp();
    
    
    await Future.delayed(const Duration(milliseconds: 800));
    
    
    int timeoutMs = 0;
    while (!AppInitializer.isInitialized && timeoutMs < 3000) {
      await Future.delayed(const Duration(milliseconds: 100));
      timeoutMs += 100;
    }
    
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => _initialScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500), 
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F2EB),
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/wokeLogo_t.png',
                width: 100, 
                height: 100, 
              ), 
              const Text(
                'woque',
                style: TextStyle(
                  fontSize: 20,
                  color: Color.fromARGB(255, 140, 122, 107),
                  fontWeight: FontWeight.w700,
                  shadows: [
                    Shadow(
                      offset: Offset(0.0, 1.0),
                      blurRadius: 2,
                      color: Color.fromRGBO(0, 0, 0, 0.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _initialScreen() {
  
  try {
    final userData = getUserData();
    if (userData.name == null || userData.name!.isEmpty) {
      
      return const WalkthroughScreen();
    } else {
      
      return const MainScreen();
    }
  } catch (e) {
    debugPrint("Error getting user data: $e");
    
    return const WalkthroughScreen();
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  int _previousIndex = 0;
  double _opacity = 1.0;
  
  
  final Duration _animationDuration = const Duration(milliseconds: 50);

  final List<Widget> _pages = [
    const QuestionsPage(),
    const JournalPage(),
    const AnalyticsPage(),
    const SettingsPage(),
  ];

  final List<IconData> _icons = [
    Icons.question_answer_outlined,
    Icons.book_outlined,
    Icons.analytics_outlined,
    Icons.settings_outlined,
  ];

  final List<String> _labels = [
    'Reflect',
    'Journal',
    'Track',
    'Settings',
  ];

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showDailyMoodCheckIn();
    });
  }

  Future<void> _showDailyMoodCheckIn() async {
    await MoodCheckIn.showDailyCheckIn(context);
  }

  
  void _changePage(int index) {
    if (_currentIndex == index) return;
    
    setState(() {
      _opacity = 0.5;
      _previousIndex = _currentIndex;
    });
    
    Future.delayed(_animationDuration, () {
      setState(() {
        _currentIndex = index;
        _opacity = 1.0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, 
      body: Stack(
        children: [
          
          Opacity(
            opacity: 1.0 - _opacity,
            child: _pages[_previousIndex],
          ),
          
          AnimatedOpacity(
            opacity: _opacity,
            duration: _animationDuration,
            curve: Curves.easeInOut,
            child: _pages[_currentIndex],
          ),
        ],
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(16.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30.0),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.95),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                _icons.length,
                (index) => _buildNavItem(index),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final bool isSelected = _currentIndex == index;
    
    return InkWell(
      onTap: () => _changePage(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCirc,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20.0 : 15.0,
          vertical: 10.0,
        ),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.secondary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCirc,
              child: Icon(
                _icons[index],
                color: isSelected 
                    ? Theme.of(context).colorScheme.tertiary
                    : Theme.of(context).colorScheme.secondary,
                size: isSelected ? 24.0 : 20.0,
              ),
            ),
            ClipRect(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCirc,
                width: isSelected ? 70.0 : 0.0,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    _labels[index],
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.tertiary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.0,
                    ),
                    overflow: TextOverflow.clip,
                    softWrap: false,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
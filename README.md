# Woque 🌱

**Your Daily Reflection Journey** - Track your growth through consistent self-reflection and see how you've evolved over time.

[![Download Beta version on Testflight](https://testflight.apple.com/join/FSrH8a6p)](#)

## 🌟 About Woque

Woque is a personal growth and self-reflection app that presents you with the same thought-provoking question on the same day each year. By comparing your answers across years, you can witness your personal evolution, track your mindset changes, and celebrate your growth journey.

## ✨ Features

### 📅 **Daily Questions System**
- **365 Unique Questions**: A carefully curated question for each day of the year
- **Annual Repetition**: Same question returns next year for comparison
- **Leap Year Support**: Special handling for February 29th
- **Question History**: View all your previous answers to the same question

### 🎯 **Personal Growth Tracking**
- **Yearly Comparisons**: See how your answers evolve over time
- **Growth Streaks**: Build daily reflection habits with streak tracking
- **Progress Analytics**: Visualize your consistency and growth patterns
- **Word Count Tracking**: Monitor your reflection depth over time

### 📝 **Journal Integration**
- **Flexible Prompts**: 90+ diverse journal prompts for deeper reflection
- **Image Support**: Add photos to your journal entries
- **Font Customization**: Adjustable text size for comfortable writing
- **Entry Management**: Organize and search through your reflections

### 📊 **Analytics & Insights**
- **AI-Powered Analysis**: Get insights into your growth patterns
- **Mood Timeline**: Track emotional patterns over weeks
- **Theme Detection**: Identify recurring topics in your reflections
- **Progress Visualization**: Charts and graphs of your journey

### 🏆 **Reward System**
- **7 Achievement Badges**: From Initiate (5 days) to Alchemist (1 year)
- **Streak Milestones**: Celebrate consistency achievements
- **Growth Celebrations**: Visual rewards for reaching milestones
- **Progress Motivation**: Gamified approach to habit building

### 🎨 **User Experience**
- **Clean Interface**: Minimalist design focused on reflection
- **Dark Mode Optimized**: Comfortable viewing in any lighting
- **Smooth Animations**: Engaging micro-interactions
- **Intuitive Navigation**: Easy access to all features

## 🛠️ Technical Architecture

### 📱 **Built With Flutter**
- **Cross-Platform**: Native performance on iOS and Android
- **State Management**: Provider pattern for reactive UI
- **Local Storage**: Hive database for offline-first experience
- **AI Integration**: OpenAI API for growth analysis

### 🗄️ **Data Management**
- **Hive Database**: NoSQL local storage for all user data
- **Question System**: Smart day-of-year mapping with leap year handling
- **Image Handling**: Local storage with file path management
- **Backup Ready**: Data structure designed for future cloud sync

### 🔧 **Key Technical Features**
- **Offline-First**: Full functionality without internet connection
- **Performance Optimized**: Efficient data queries and UI rendering
- **Memory Management**: Proper disposal of resources and controllers
- **Error Handling**: Graceful fallbacks and user-friendly error messages

## 📋 App Structure

```
lib/
├── main.dart                    # App entry point
├── pages/
│   ├── questions_page.dart      # Daily question interface
│   ├── journal_page.dart        # Journal prompts and writing
│   └── analytics_page.dart      # Progress tracking and insights
├── services/
│   ├── ai_service.dart          # OpenAI integration
│   ├── mood_service.dart        # Mood tracking logic
│   └── notification_service.dart # Reminder notifications
├── models/
│   ├── question_hive.dart       # Question answer data model
│   ├── journal_hive.dart        # Journal entry data model
│   ├── mood_hive.dart          # Mood entry data model
│   └── rewards_hive.dart        # Achievement system
└── widgets/
    ├── mood_chart.dart          # Mood visualization
    ├── growth_widgets.dart      # Analytics components
    └── badge_celebration.dart   # Achievement animations
```

## 🎨 Core Features Deep Dive

### 📝 **Question System Logic**
```dart
// Maps calendar days to consistent question indices
String _getQuestionKey(DateTime date) {
  final dayOfYear = _getDayOfYear(date);
  if (_isLeapDay(date)) {
    return 'leapDay';
  }
  return 'day_$dayOfYear';
}
```

### 🔄 **Streak Calculation**
- **Current Streak**: Counts consecutive days with answers
- **Grace Period**: One-day buffer to maintain streaks
- **Smart Reset**: Automatically resets at day boundaries
- **Historical Analysis**: Scans up to 2 years of data

### 🧠 **AI Growth Analysis**
- **Pattern Recognition**: Identifies themes in your writing
- **Sentiment Analysis**: Tracks emotional evolution
- **Growth Insights**: Personalized observations about your journey
- **Category Mapping**: Organizes reflections into meaningful groups

### 🎁 **Achievement System**
Progressive badges reward consistency:
- **Initiate** (5 days) → **Seeker** (15 days) → **Observer** (30 days)
- **Reflector** (90 days) → **Guide** (180 days) → **Sage** (270 days)
- **Alchemist** (365 days) - Master of personal transformation

## 📊 User Journey

### 🌅 **Daily Flow**
1. **Morning Question**: Receive today's reflection prompt
2. **Thoughtful Response**: Write your honest answer
3. **Historical View**: Compare with previous years (if available)
4. **Streak Building**: Maintain daily consistency
5. **Growth Tracking**: Watch your progress unfold

### 📝 **Journal Experience**
1. **Prompt Selection**: Choose from rotating journal prompts
2. **Rich Writing**: Add text, images, and personal insights
3. **Organization**: Browse and search past entries
4. **Analytics**: See writing patterns and themes

### 📈 **Progress Monitoring**
1. **Streak Tracking**: Visualize consistency habits
2. **Word Analytics**: Monitor reflection depth
3. **Mood Patterns**: Understand emotional trends
4. **AI Insights**: Receive personalized growth observations

## 🔑 Key Technical Implementations

### 🗃️ **Hive Database Strategy**
```dart
// Efficient question-answer storage
Box<QuestionAnswer> questionAnswers;
Box<JournalEntry> journalEntries;
Box<MoodEntry> moodEntries;
Box<Reward> achievements;
```

### 📱 **State Management Pattern**
- **Provider**: Global settings and user preferences
- **StatefulWidget**: Local UI state and animations
- **ValueListenableBuilder**: Reactive database updates
- **FutureBuilder**: Async data loading with loading states

### 🎯 **Performance Optimizations**
- **Lazy Loading**: Load data only when needed
- **Efficient Queries**: Optimized database operations
- **Image Compression**: Automatic image optimization
- **Memory Management**: Proper widget disposal

## 🎨 Design Philosophy

### 🧘 **Mindful Interface**
- **Minimal Distractions**: Clean, focused design
- **Comfortable Typography**: Readable fonts and sizing
- **Calming Colors**: Soothing color palette
- **Intuitive Flow**: Natural user journey progression

### 📱 **Mobile-First Approach**
- **Touch-Friendly**: Large tap targets and gestures
- **Keyboard Optimization**: Smooth text input experience
- **Responsive Design**: Adapts to all screen sizes
- **Platform Guidelines**: Follows iOS and Android standards

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.0+)
- Dart SDK (2.17+)
- iOS 12.0+ / Android API 21+

### Installation
1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Set up Hive database:
   ```bash
   flutter packages pub run build_runner build
   ```
4. Configure environment variables
5. Run the app:
   ```bash
   flutter run
   ```

## 🔐 Configuration Required

- **OpenAI API Key**: For AI-powered growth analysis
- **Local Storage**: Hive database initialization
- **Notification Permissions**: For daily reminders
- **Image Permissions**: For journal photo attachments

## 🎯 Target Audience

- **Self-Improvement Enthusiasts**: People committed to personal growth
- **Journal Writers**: Those who enjoy reflective writing
- **Habit Builders**: Users wanting to develop consistency
- **Growth Trackers**: Individuals interested in measuring progress
- **Mindfulness Practitioners**: People seeking deeper self-awareness

## 💡 Why Woque?

### 🌱 **Unique Value Proposition**
- **Temporal Perspective**: Compare yourself across years, not just days
- **Consistency Building**: Gentle habit formation through daily questions
- **Growth Visualization**: See your evolution in real, measurable ways
- **AI-Enhanced Insights**: Technology-powered self-discovery

### 🎯 **Core Benefits**
- 🧠 **Self-Awareness**: Develop deeper understanding of your thoughts
- 📈 **Growth Tracking**: Measure personal development over time
- 🎯 **Habit Formation**: Build sustainable reflection practices
- 🏆 **Achievement Motivation**: Gamified progress encouragement
- 🔍 **Pattern Recognition**: Identify growth trends and cycles

---

## 🌟 Experience Your Growth Journey

Transform daily reflection into a powerful tool for personal evolution. With Woque, every answer becomes a stepping stone in your growth story.

[![Download Beta version on Testflight](https://testflight.apple.com/join/FSrH8a6p)](#)

---

## 🏷️ Tags

`#Flutter` `#Dart` `#PersonalGrowth` `#SelfReflection` `#JournalApp` `#HabitTracker` `#MindfulnessApp` `#GrowthTracking` `#DailyQuestions` `#Hive` `#OpenAI` `#MobileApp` `#SelfImprovement` `#Reflection` `#ProgressTracking` `#AchievementSystem` `#StreakTracker` `#AIInsights` `#CrossPlatform`

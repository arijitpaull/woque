import 'package:hive/hive.dart';

part 'mood_hive.g.dart';

@HiveType(typeId: 1) 
class MoodEntry {
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  final List<String> moods;

  MoodEntry({
    required this.date,
    required this.moods,
  });
}

Future<void> initMoodHive() async {
  Hive.registerAdapter(MoodEntryAdapter());
  await Hive.openBox<MoodEntry>('moods');
}

class MoodService {
  static Box<MoodEntry> get _moodBox => Hive.box<MoodEntry>('moods');

  
  static Future<void> saveMoods(List<String> moods) async {
    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month}-${today.day}';
    
    await _moodBox.put(
      dateKey,
      MoodEntry(
        date: DateTime(today.year, today.month, today.day),
        moods: moods,
      ),
    );
  }

  
  static bool hasRecordedMoodToday() {
    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month}-${today.day}';
    return _moodBox.containsKey(dateKey);
  }

  
  static List<MoodEntry> getAllMoodEntries() {
    return _moodBox.values.toList();
  }

  
  static MoodEntry? getMoodEntryForDate(DateTime date) {
    final dateKey = '${date.year}-${date.month}-${date.day}';
    return _moodBox.get(dateKey);
  }
}
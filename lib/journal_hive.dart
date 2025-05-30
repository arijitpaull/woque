import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'journal_hive.g.dart';

@HiveType(typeId: 0)
class JournalEntry {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String prompt;
  
  @HiveField(2)
  final String entry;
  
  @HiveField(3)
  final DateTime date;
  
  @HiveField(4)
  final List<String> imagePaths;

  JournalEntry({
    required this.prompt,
    required this.entry,
    required this.date,
    this.imagePaths = const [],
    String? id,
  }) : id = id ?? const Uuid().v4();
}

Future<void> initJournalHive() async {
  Hive.registerAdapter(JournalEntryAdapter());
  await Hive.openBox<JournalEntry>('journalEntries');
}

Future<void> saveJournalEntry(
  String prompt, 
  String entry, 
  DateTime date, {
  List<String> imagePaths = const [],
  String? id,
}) async {
  final box = Hive.box<JournalEntry>('journalEntries');
  final journalEntry = JournalEntry(
    prompt: prompt,
    entry: entry,
    date: date,
    imagePaths: imagePaths,
    id: id,
  );
  await box.put(journalEntry.id, journalEntry);
}

Future<void> deleteJournalEntries(List<String> entryIds) async {
  final box = Hive.box<JournalEntry>('journalEntries');
  await box.deleteAll(entryIds);
}

Future<List<JournalEntry>> getAllJournalEntries() async {
  final box = Hive.box<JournalEntry>('journalEntries');
  return box.values.toList();
}

Future<List<JournalEntry>> getEntriesByPrompt(String prompt) async {
  final box = Hive.box<JournalEntry>('journalEntries');
  return box.values.where((entry) => entry.prompt == prompt).toList();
}

Future<int> countEntriesByPrompt(String prompt) async {
  final box = Hive.box<JournalEntry>('journalEntries');
  return box.values.where((entry) => entry.prompt == prompt).length;
}

Future<Map<String, int>> getPromptEntryCounts() async {
  final box = Hive.box<JournalEntry>('journalEntries');
  final Map<String, int> counts = {};
  
  for (var entry in box.values) {
    counts[entry.prompt] = (counts[entry.prompt] ?? 0) + 1;
  }
  
  return counts;
}


Future<void> migrateExistingEntries() async {
  final box = Hive.box<JournalEntry>('journalEntries');
  final entries = box.values.toList();
  
  
  await box.clear();
  
  
  for (final entry in entries) {
    await saveJournalEntry(
      entry.prompt,
      entry.entry,
      entry.date,
      imagePaths: entry.imagePaths,
    );
  }
}
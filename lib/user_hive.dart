import 'package:hive/hive.dart';

part 'user_hive.g.dart'; 

@HiveType(typeId: 3) 
class UserData {
  @HiveField(0)
  final String? name;
  
  @HiveField(1)
  final String title;
  
  @HiveField(2) 
  late final int maxStreak;

  UserData({
    this.name,
    this.title = 'Newbie', 
    this.maxStreak = 0,    
  });

  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'title': title,
      'maxStreak': maxStreak,
    };
  }

  Future<void> updateUserData(UserData userData) async {
  final box = Hive.box('userBox');
  await box.put('userData', userData);
}

  
  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      name: json['name'],
      title: json['title'] ?? 'Newbie',
      maxStreak: json['maxStreak'] ?? 0,
    );
  }

  
  UserData copyWith({
    String? name,
    String? title,
    int? maxStreak,
  }) {
    return UserData(
      name: name ?? this.name,
      title: title ?? this.title,
      maxStreak: maxStreak ?? this.maxStreak,
    );
  }
}


Future<void> initUserHive() async {
  if (!Hive.isBoxOpen('userBox')) {
    await Hive.openBox('userBox');
  }
}


UserData getUserData() {
  final box = Hive.box('userBox');
  final userData = box.get('userData');
  
  if (userData == null) {
    return UserData();
  }
  
  
  if (userData is Map) {
    return UserData.fromJson(Map<String, dynamic>.from(userData));
  }
  return userData as UserData;
}


Future<void> saveUserData(UserData userData) async {
  final box = Hive.box('userBox');
  await box.put('userData', userData);
}


Future<void> updateUserName(String name) async {
  final userData = getUserData();
  await saveUserData(userData.copyWith(name: name));
}


Future<void> updateUserTitle(String title) async {
  final userData = getUserData();
  await saveUserData(userData.copyWith(title: title));
}


Future<void> updateMaxStreak(int newStreak) async {
  final userData = getUserData();
  if (newStreak > userData.maxStreak) {
    await saveUserData(userData.copyWith(maxStreak: newStreak));
  }
}


bool isFirstTime() {
  final userData = getUserData();
  return userData.name == null;
}


int getMaxStreak() {
  return getUserData().maxStreak;
}
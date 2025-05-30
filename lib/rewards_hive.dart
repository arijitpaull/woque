import 'package:hive/hive.dart';
import 'package:woke/user_hive.dart';

part 'rewards_hive.g.dart'; 

@HiveType(typeId: 5) 
class Reward {
  @HiveField(0)
  final String title;
  
  @HiveField(1)
  final String avatarImagePath;
  
  @HiveField(2)
  final String iconImagePath;
  
  @HiveField(3)
  final String description;
  
  @HiveField(4)
  final int requiredDays;
  
  @HiveField(5)
  final bool isUnlocked;

  Reward({
    required this.title,
    required this.avatarImagePath,
    required this.iconImagePath,
    required this.description,
    required this.requiredDays,
    this.isUnlocked = false,
  });

  
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'avatarImagePath': avatarImagePath,
      'iconImagePath': iconImagePath,
      'description': description,
      'requiredDays': requiredDays,
      'isUnlocked': isUnlocked,
    };
  }

  
  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      title: json['title'],
      avatarImagePath: json['avatarImagePath'],
      iconImagePath: json['iconImagePath'],
      description: json['description'],
      requiredDays: json['requiredDays'],
      isUnlocked: json['isUnlocked'] ?? false,
    );
  }

  
  Reward copyWith({
    String? title,
    String? avatarImagePath,
    String? iconImagePath,
    String? description,
    int? requiredDays,
    bool? isUnlocked,
  }) {
    return Reward(
      title: title ?? this.title,
      avatarImagePath: avatarImagePath ?? this.avatarImagePath,
      iconImagePath: iconImagePath ?? this.iconImagePath,
      description: description ?? this.description,
      requiredDays: requiredDays ?? this.requiredDays,
      isUnlocked: isUnlocked ?? this.isUnlocked,
    );
  }
}


Future<void> initRewardsHive() async {
  if (!Hive.isBoxOpen('rewardsBox')) {
    await Hive.openBox('rewardsBox');
    await _initializeDefaultRewards();
  }
}


Future<void> _initializeDefaultRewards() async {
  final box = Hive.box('rewardsBox');
  
  
  if (box.isEmpty) {
    final List<Reward> defaultRewards = [
      Reward(
        title: 'Initiate',
        avatarImagePath: 'assets/initiate_av.png',
        iconImagePath: 'assets/initiate_ic.png',
        description: 'You\'ve taken your first steps on the journey of self-discovery and growth.',
        requiredDays: 5,
      ),
      Reward(
        title: 'Seeker',
        avatarImagePath: 'assets/seeker_av.png',
        iconImagePath: 'assets/seeker_ic.png',
        description: 'You\'re actively seeking deeper understanding and personal growth.',
        requiredDays: 15,
      ),
      Reward(
        title: 'Observer',
        avatarImagePath: 'assets/observer_av.png',
        iconImagePath: 'assets/observer_ic.png',
        description: 'You\'ve developed the discipline to observe your thoughts and patterns consistently.',
        requiredDays: 30,
      ),
      Reward(
        title: 'Reflector',
        avatarImagePath: 'assets/reflector_av.png',
        iconImagePath: 'assets/reflector_ic.png',
        description: 'Your commitment to self-reflection has become a cornerstone of your personal growth journey.',
        requiredDays: 90,
      ),
      Reward(
        title: 'Guide',
        avatarImagePath: 'assets/guide_av.png',
        iconImagePath: 'assets/guide_ic.png',
        description: 'Your insights have deepened to the point where you can guide both yourself and others.',
        requiredDays: 180,
      ),
      Reward(
        title: 'Sage',
        avatarImagePath: 'assets/sage_av.png',
        iconImagePath: 'assets/sage_ic.png',
        description: 'You\'ve accumulated profound wisdom through consistent introspection and mindfulness.',
        requiredDays: 270,
      ),
      Reward(
        title: 'Alchemist',
        avatarImagePath: 'assets/alchemist_av.png',
        iconImagePath: 'assets/alchemist_ic.png',
        description: 'You\'ve mastered the art of transforming daily reflections into profound personal growth.',
        requiredDays: 365,
      ),
    ];
    
    
    for (var reward in defaultRewards) {
      await box.put(reward.title, reward);
    }
  }
}


List<Reward> getAllRewards() {
  final box = Hive.box('rewardsBox');
  return box.values.map((rewardData) {
    
    if (rewardData is Map) {
      return Reward.fromJson(Map<String, dynamic>.from(rewardData));
    }
    return rewardData as Reward;
  }).toList();
}


Reward? getReward(String title) {
  final box = Hive.box('rewardsBox');
  final rewardData = box.get(title);
  
  if (rewardData == null) {
    return null;
  }
  
  
  if (rewardData is Map) {
    return Reward.fromJson(Map<String, dynamic>.from(rewardData));
  }
  return rewardData as Reward;
}


Future<void> unlockReward(String title) async {
  final box = Hive.box('rewardsBox');
  final reward = getReward(title);
  
  if (reward != null) {
    
    if (!reward.isUnlocked) {
      final updatedReward = reward.copyWith(isUnlocked: true);
      await box.put(title, updatedReward);
      
      
      await updateUserTitle(title);
    }
  }
}


Reward? getHighestUnlockedReward() {
  final rewards = getAllRewards().where((r) => r.isUnlocked).toList();
  if (rewards.isEmpty) {
    return null;
  }
  
  
  rewards.sort((a, b) => b.requiredDays.compareTo(a.requiredDays));
  return rewards.first;
}


Future<Reward?> checkAndUnlockReward(int streak) async {
  Reward? unlocked;
  
  final rewards = getAllRewards();
  
  rewards.sort((a, b) => a.requiredDays.compareTo(b.requiredDays));
  
  for (var reward in rewards) {
    if (streak >= reward.requiredDays && !reward.isUnlocked) {
      await unlockReward(reward.title);
      unlocked = reward.copyWith(isUnlocked: true);
    }
  }
  
  return unlocked;
}


List<Reward> getUnlockedRewards() {
  return getAllRewards().where((reward) => reward.isUnlocked).toList();
}
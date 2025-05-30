

part of 'rewards_hive.dart';





class RewardAdapter extends TypeAdapter<Reward> {
  @override
  final int typeId = 5;

  @override
  Reward read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Reward(
      title: fields[0] as String,
      avatarImagePath: fields[1] as String,
      iconImagePath: fields[2] as String,
      description: fields[3] as String,
      requiredDays: fields[4] as int,
      isUnlocked: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Reward obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.avatarImagePath)
      ..writeByte(2)
      ..write(obj.iconImagePath)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.requiredDays)
      ..writeByte(5)
      ..write(obj.isUnlocked);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RewardAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
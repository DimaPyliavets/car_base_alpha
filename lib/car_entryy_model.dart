import 'package:hive_flutter/hive_flutter.dart';

@HiveType(typeId: 0)
class CarEntry extends HiveObject {
  @HiveField(0)
  String carNumber;

  @HiveField(1)
  String name;

  @HiveField(2)
  String phoneNumber;

  @HiveField(3)
  String companyName;

  @HiveField(4)
  String carType;

  @HiveField(5)
  DateTime departureDateTime;

  @HiveField(6)
  String comment;

  CarEntry({
    required this.carNumber,
    required this.name,
    required this.phoneNumber,
    required this.companyName,
    required this.carType,
    required this.departureDateTime,
    required this.comment,
  });
}

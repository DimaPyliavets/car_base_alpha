import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:max_baza/car_entry_adapter.dart';
import 'package:max_baza/car_entryy_model.dart';
import 'package:max_baza/my_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(CarEntryAdapter());
  //await Hive.openBox<CarEntry>('cars');
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  if (!Hive.isBoxOpen('cars')) {
    await Hive.openBox<CarEntry>('cars');
  }
  runApp(const MyApp());
}

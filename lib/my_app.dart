import 'package:flutter/material.dart';
import 'package:max_baza/home_page.dart';
import 'package:max_baza/theme_provider.dart';
import 'package:provider/provider.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              brightness: themeProvider.isDarkMode
                  ? Brightness.dark
                  : Brightness.light,
              useSystemColors: true,
              primarySwatch: Colors.blue,
              useMaterial3: true,
            ),
            home: const HomePage(),
          );
        },
      ),
    );
  }
}

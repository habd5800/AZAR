import 'package:flutter/material.dart';
import 'data/azar_db.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AzarDb.instance.database;
  runApp(const AzarApp());
}

class AzarApp extends StatelessWidget {
  const AzarApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'آذر | AZAR',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Roboto',
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF172B4D), primary: const Color(0xFF172B4D), secondary: const Color(0xFFF28C28)),
          scaffoldBackgroundColor: const Color(0xFFF3F5F8),
          appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF172B4D), foregroundColor: Colors.white, centerTitle: false),
          inputDecorationTheme: InputDecorationTheme(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.white),
        ),
        builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
        home: const HomeScreen(),
      );
}

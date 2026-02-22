import 'package:flutter/material.dart';
import 'helpers/database_helper.dart';
import 'screens/home.dart';
import 'screens/report.dart';
import 'screens/edit_station.dart';
import 'screens/list_screen.dart';
import 'screens/filter_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper().database; // init DB on startup
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Election Watch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/':       (ctx) => const HomeScreen(),
        '/report': (ctx) => const ReportScreen(),
        '/edit':   (ctx) => const EditStationScreen(),
        '/list':   (ctx) => const ListScreen(),
        '/filter': (ctx) => const FilterScreen(),
      },
    );
  }
}

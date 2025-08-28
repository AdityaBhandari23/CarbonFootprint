import 'package:flutter/material.dart';
import 'services/carbon_factors_service.dart';
import 'services/database_service.dart';
import 'screens/main_screen.dart';

void main() async {
  try {
    // Ensure Flutter binding is initialized
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize database service
    await DatabaseService.initialize();
    
    // Load carbon factors at startup
    await CarbonFactorsService().loadCarbonFactors();
    runApp(const CarbonFootprintApp());
  } catch (e) {
    // Log initialization errors but continue
    debugPrint('Error during app initialization: $e');
    // Still try to run the app even if initialization fails partially
    runApp(const CarbonFootprintApp());
  }
}

class CarbonFootprintApp extends StatelessWidget {
  const CarbonFootprintApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Carbon Footprint Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          elevation: 6,
        ),
      ),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
} 
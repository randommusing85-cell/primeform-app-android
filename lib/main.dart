import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/plan_screen.dart';
import 'screens/checkin_screen.dart';
import 'screens/trends_screen.dart';
import 'screens/my_plan_screen.dart';
import 'screens/workout_plan_screen.dart';
import 'screens/my_workout_plan_screen.dart';
import 'screens/today_workout_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: PrimeFormApp()));
}

class PrimeFormApp extends ConsumerWidget {
  const PrimeFormApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'PrimeForm',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/plan': (context) => const PlanScreen(),
        '/checkin': (context) => const CheckInScreen(),
        '/trends': (context) => const TrendsScreen(),
        '/myplan': (context) => const MyPlanScreen(),
        '/workout': (context) => const WorkoutPlanScreen(),
        '/my-workout': (context) => const MyWorkoutPlanScreen(),
        '/today-workout': (context) => const TodayWorkoutScreen(),
      },
    );
  }
}

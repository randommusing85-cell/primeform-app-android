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
import 'screens/onboarding_screen.dart';
import 'state/providers.dart';

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
      home: const AppInitializer(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
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

/// Checks if user profile exists and routes accordingly
class AppInitializer extends ConsumerWidget {
  const AppInitializer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading app: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(userProfileProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (profile) {
        // If no profile exists, show onboarding
        if (profile == null) {
          return const OnboardingScreen();
        }

        // Profile exists, show home screen
        return const HomeScreen();
      },
    );
  }
}
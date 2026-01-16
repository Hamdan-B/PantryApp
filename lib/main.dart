import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pantry_app/core/constants/app_constants.dart';
import 'package:pantry_app/core/theme/app_theme.dart';
import 'package:pantry_app/presentation/providers/auth_provider.dart';
import 'package:pantry_app/presentation/providers/theme_provider.dart';
import 'package:pantry_app/presentation/screens/auth/login_screen.dart';
import 'package:pantry_app/presentation/screens/auth/register_screen.dart';
import 'package:pantry_app/presentation/screens/home/home_screen.dart';
import 'package:pantry_app/presentation/screens/pantry/pantry_screen.dart';
import 'package:pantry_app/presentation/screens/planner/planner_screen.dart';
import 'package:pantry_app/presentation/screens/profile/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load environment variables from .env file
  await dotenv.load(fileName: '.env');
  // Initialize Supabase here when you have API keys
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );
  runApp(const ProviderScope(child: PantryApp()));
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const MainScreen(),
      ),
    ],
    redirect: (context, state) {
      return authState.when(
        data: (authState) {
          final isLoggedIn = authState.session != null;
          final isLoggingIn =
              state.uri.path == '/login' || state.uri.path == '/register';

          if (!isLoggedIn && !isLoggingIn) {
            return '/login';
          }

          if (isLoggedIn && isLoggingIn) {
            return '/';
          }

          return null;
        },
        loading: () => null,
        error: (err, stack) {
          return '/login';
        },
      );
    },
  );
});

class PantryApp extends ConsumerWidget {
  const PantryApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final isDarkMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      routerConfig: router,
      title: 'Pantry App',
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    PantryScreen(),
    PlannerScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart),
            label: 'Pantry',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month),
            label: 'Planner',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

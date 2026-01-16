import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Theme mode state
class ThemeModeNotifier extends StateNotifier<bool> {
  final SharedPreferences? prefs;

  ThemeModeNotifier(this.prefs) : super(prefs?.getBool('darkMode') ?? false);

  Future<void> toggleTheme() async {
    state = !state;
    await prefs?.setBool('darkMode', state);
  }

  void setDarkMode(bool isDark) {
    state = isDark;
    prefs?.setBool('darkMode', isDark);
  }
}

final sharedPreferencesProvider =
    FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, bool>((ref) {
  // We need to watch the FutureProvider and handle loading/error states
  final prefs = ref.watch(sharedPreferencesProvider);

  return prefs.maybeWhen(
    data: (p) => ThemeModeNotifier(p),
    orElse: () => ThemeModeNotifier(null),
  );
});

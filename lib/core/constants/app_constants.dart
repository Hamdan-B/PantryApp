import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // Supabase Configuration - Read from .env file
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  // TheMealDB API
  static const String mealDbBaseUrl = 'https://www.themealdb.com/api/json/v1/1';

  // Storage buckets
  static const String userAvatarsBucket = 'user-avatars';

  // Database tables
  static const String usersTable = 'users';
  static const String pantryItemsTable = 'pantry_items';
  static const String plannerTable = 'planner';
  static const String usageLogsTable = 'usage_logs';

  // Pantry categories
  static const List<String> pantryCategories = [
    'Spices',
    'Meat',
    'Grains',
    'Vegetables',
    'Fruits',
    'Dairy',
    'Oils / Liquids',
  ];

  // Category to icon mapping
  static const Map<String, String> categoryEmojis = {
    'Spices': '🧂',
    'Meat': '🥩',
    'Grains': '🌾',
    'Vegetables': '🥦',
    'Fruits': '🍎',
    'Dairy': '🧈',
    'Oils / Liquids': '🛢️',
  };

  // Category items
  static const Map<String, List<String>> categoryItems = {
    'Spices': [
      'Salt',
      'Sugar',
      'Black Pepper',
      'Red Chili Powder',
      'Turmeric',
      'Cumin',
      'Coriander',
      'Garam Masala',
    ],
    'Meat': ['Cow', 'Goat', 'Lamb'],
    'Grains': ['Rice', 'Wheat Flour', 'Oats', 'Corn Flour'],
    'Vegetables': [
      'Onion',
      'Tomato',
      'Potato',
      'Garlic',
      'Ginger',
      'Carrot',
      'Bell Pepper',
      'Spinach',
    ],
    'Fruits': ['Apple', 'Banana', 'Orange', 'Lemon'],
    'Dairy': ['Milk', 'Butter', 'Cheese', 'Yogurt'],
    'Oils / Liquids': ['Cooking Oil', 'Olive Oil', 'Vinegar', 'Soy Sauce'],
  };

  // Units by category
  static const Map<String, String> categoryUnits = {
    'Spices': 'grams',
    'Meat': 'grams',
    'Grains': 'grams',
    'Vegetables': 'grams',
    'Fruits': 'grams',
    'Dairy': 'grams',
    'Oils / Liquids': 'milliliters',
  };

  // Meal types for planner
  static const List<String> mealTypes = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snack',
  ];

  // Time filters for analytics
  static const List<String> timeFilters = [
    'Last 7 days',
    'Last 30 days',
    'Custom range',
  ];
}

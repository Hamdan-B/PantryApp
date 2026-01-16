import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/core/constants/app_constants.dart';
import 'package:pantry_app/presentation/providers/planner_provider.dart';
import 'package:pantry_app/presentation/providers/auth_provider.dart';
import 'package:pantry_app/data/models/planner_meal_model.dart';

class DayPlannerScreen extends ConsumerWidget {
  final DateTime date;

  const DayPlannerScreen({Key? key, required this.date}) : super(key: key);

  String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];

    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealsAsync = ref.watch(plannedMealsProvider(date));

    return Scaffold(
      appBar: AppBar(
        title: Text(_formatDate(date)),
      ),
      body: mealsAsync.when(
        data: (meals) {
          // Group meals by type
          final mealsByType = <String, List<PlannerMealModel>>{};
          for (final meal in meals) {
            mealsByType.putIfAbsent(meal.mealType, () => []).add(meal);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final mealType in AppConstants.mealTypes)
                _MealTypeSection(
                  mealType: mealType,
                  meals: mealsByType[mealType] ?? [],
                  date: date,
                  onDelete: (meal) {
                    if (meal.id != null) {
                      ref
                          .read(plannerNotifierProvider.notifier)
                          .deleteMeal(meal.id!);
                    }
                  },
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $err'),
            ],
          ),
        ),
      ),
    );
  }
}

class _MealTypeSection extends ConsumerWidget {
  final String mealType;
  final List<PlannerMealModel> meals;
  final DateTime date;
  final Function(PlannerMealModel) onDelete;

  const _MealTypeSection({
    required this.mealType,
    required this.meals,
    required this.date,
    required this.onDelete,
  });

  IconData _getMealIcon(String mealType) {
    switch (mealType) {
      case 'Breakfast':
        return Icons.free_breakfast;
      case 'Lunch':
        return Icons.lunch_dining;
      case 'Dinner':
        return Icons.dinner_dining;
      case 'Snack':
        return Icons.cookie;
      default:
        return Icons.restaurant;
    }
  }

  void _showAddMealDialog(BuildContext context, WidgetRef ref) {
    final dishNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add $mealType'),
        content: TextField(
          controller: dishNameController,
          decoration: const InputDecoration(
            labelText: 'Dish Name',
            hintText: 'e.g., Biryani',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final authState = ref.read(authStateProvider).value;
              final user = authState?.session?.user;
              if (dishNameController.text.isNotEmpty && user != null) {
                final meal = PlannerMealModel(
                  userId: user.id,
                  date: date,
                  mealType: mealType,
                  dishName: dishNameController.text,
                  createdAt: DateTime.now(),
                );
                ref.read(plannerNotifierProvider.notifier).addMeal(meal);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: Icon(_getMealIcon(mealType), color: Colors.green),
            title: Text(
              mealType,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => _showAddMealDialog(context, ref),
            ),
          ),
          if (meals.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                'No $mealType planned',
                style: TextStyle(color: Colors.grey[600]),
              ),
            )
          else
            ...meals.map(
              (meal) => ListTile(
                leading: const Icon(Icons.restaurant_menu),
                title: Text(meal.dishName),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Meal'),
                        content: Text('Delete ${meal.dishName}?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              onDelete(meal);
                              Navigator.pop(context);
                            },
                            child: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/presentation/providers/recipe_provider.dart';
import 'package:shimmer/shimmer.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final searchController = TextEditingController();
  String searchQuery = '';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recipesAsyncValue = searchQuery.isEmpty
        ? ref.watch(randomRecipesProvider)
        : ref.watch(mealSearchProvider(searchQuery));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipes'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Invalidate the providers to trigger a refresh
          if (searchQuery.isEmpty) {
            ref.invalidate(randomRecipesProvider);
          } else {
            ref.invalidate(mealSearchProvider(searchQuery));
          }
          // Wait a bit for the new data to load
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: searchController,
                  onChanged: (value) {
                    setState(() => searchQuery = value);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search recipes...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: searchQuery.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              searchController.clear();
                              setState(() => searchQuery = '');
                            },
                            child: const Icon(Icons.clear),
                          )
                        : null,
                  ),
                ),
              ),
              recipesAsyncValue.when(
                data: (recipes) {
                  if (recipes.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          const Icon(Icons.restaurant_menu,
                              size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('No recipes found'),
                        ],
                      ),
                    );
                  }

                  return RecipeSortedList(recipes: recipes);
                },
                loading: () => ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 5,
                  itemBuilder: (context, index) => Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        height: 200,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                error: (err, stack) => Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text('Error: ${err.toString()}'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget to sort and display recipes by ingredient match percentage
class RecipeSortedList extends ConsumerStatefulWidget {
  final List<dynamic> recipes;

  const RecipeSortedList({Key? key, required this.recipes}) : super(key: key);

  @override
  ConsumerState<RecipeSortedList> createState() => _RecipeSortedListState();
}

class _RecipeSortedListState extends ConsumerState<RecipeSortedList> {
  Map<String, double> recipePercentages = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _calculatePercentages();
  }

  @override
  void didUpdateWidget(RecipeSortedList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.recipes != widget.recipes) {
      _calculatePercentages();
    }
  }

  Future<void> _calculatePercentages() async {
    setState(() => isLoading = true);
    final percentages = <String, double>{};

    for (final recipe in widget.recipes) {
      try {
        final percentage =
            await ref.read(recipeIngredientMatchProvider(recipe).future);
        percentages[recipe.id] = percentage;
      } catch (e) {
        percentages[recipe.id] = 0.0;
      }
    }

    if (mounted) {
      setState(() {
        recipePercentages = percentages;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        itemBuilder: (context, index) => Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              height: 200,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    // Sort recipes by percentage in descending order
    final sortedRecipes = List.from(widget.recipes)
      ..sort((a, b) {
        final percentageA = recipePercentages[a.id] ?? 0.0;
        final percentageB = recipePercentages[b.id] ?? 0.0;
        return percentageB.compareTo(percentageA); // Descending order
      });

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedRecipes.length,
      itemBuilder: (context, index) {
        final recipe = sortedRecipes[index];
        return RecipeCard(recipe: recipe);
      },
    );
  }
}

class RecipeCard extends ConsumerWidget {
  final dynamic recipe;

  const RecipeCard({Key? key, required this.recipe}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchAsyncValue = ref.watch(recipeIngredientMatchProvider(recipe));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          ListTile(
            leading: recipe.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      recipe.imageUrl!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey,
                          child: const Icon(Icons.restaurant_menu),
                        );
                      },
                    ),
                  )
                : Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey,
                    child: const Icon(Icons.restaurant_menu),
                  ),
            title: Text(recipe.name ?? 'Unknown Recipe'),
            subtitle: Text(
              recipe.area ?? recipe.category ?? 'No description',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => RecipeDetailScreen(recipe: recipe),
                ),
              );
            },
          ),
          matchAsyncValue.when(
            data: (percentage) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.kitchen,
                          size: 16,
                          color: _getMatchColor(percentage),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${percentage.toStringAsFixed(0)}% ingredients available',
                          style: TextStyle(
                            fontSize: 12,
                            color: _getMatchColor(percentage),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        minHeight: 6,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getMatchColor(percentage),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (err, stack) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Color _getMatchColor(double percentage) {
    if (percentage >= 75) return Colors.green;
    if (percentage >= 50) return Colors.orange;
    return Colors.red;
  }
}

class RecipeDetailScreen extends ConsumerWidget {
  final dynamic recipe;

  const RecipeDetailScreen({Key? key, required this.recipe}) : super(key: key);

  Color _getMatchColor(double percentage) {
    if (percentage >= 75) return Colors.green;
    if (percentage >= 50) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchAsyncValue = ref.watch(recipeIngredientMatchProvider(recipe));

    return Scaffold(
      appBar: AppBar(
        title: Text(recipe.name ?? 'Recipe'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (recipe.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  recipe.imageUrl!,
                  height: 250,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 24),
            Text(
              recipe.name ?? 'Recipe',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (recipe.category != null)
              Text(
                'Category: ${recipe.category}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            const SizedBox(height: 16),
            matchAsyncValue.when(
              data: (percentage) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _getMatchColor(percentage).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getMatchColor(percentage).withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.kitchen,
                            size: 24,
                            color: _getMatchColor(percentage),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${percentage.toStringAsFixed(0)}% Ingredients Available',
                            style: TextStyle(
                              fontSize: 18,
                              color: _getMatchColor(percentage),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          minHeight: 10,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getMatchColor(percentage),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            const Text(
              'Ingredients',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...recipe.getIngredientPairs().map((pair) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('${pair.key} - ${pair.value}'),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),
            if (recipe.instructions != null) ...[
              const Text(
                'Instructions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(recipe.instructions!),
            ],
          ],
        ),
      ),
    );
  }
}

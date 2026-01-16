import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/core/constants/app_constants.dart';
import 'package:pantry_app/presentation/providers/wishlist_provider.dart';
import 'package:pantry_app/presentation/providers/auth_provider.dart';
import 'package:pantry_app/data/models/wishlist_item_model.dart';

class WishlistScreen extends ConsumerStatefulWidget {
  const WishlistScreen({super.key});

  @override
  ConsumerState<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends ConsumerState<WishlistScreen> {
  String? selectedCategory;

  @override
  void initState() {
    super.initState();
    selectedCategory = AppConstants.pantryCategories.first;
  }

  void _showAddItemDialog(BuildContext context, WidgetRef ref) {
    final itemController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add to $selectedCategory'),
        content: TextField(
          controller: itemController,
          decoration: const InputDecoration(
            labelText: 'Item Name',
            hintText: 'e.g., Milk',
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
              if (itemController.text.isNotEmpty && selectedCategory != null) {
                final authState = ref.read(authStateProvider).value;
                final user = authState?.session?.user;
                if (user != null) {
                  final item = WishlistItemModel(
                    userId: user.id,
                    itemName: itemController.text.trim(),
                    category: selectedCategory!,
                    createdAt: DateTime.now(),
                  );
                  ref.read(wishlistNotifierProvider.notifier).addItem(item);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${itemController.text} added to wishlist'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wishlistAsync = ref.watch(wishlistItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wishlist'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Category filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ...AppConstants.pantryCategories.map((category) {
                  final isSelected = category == selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: FilterChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => selectedCategory = category);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          // Items list
          Expanded(
            child: wishlistAsync.when(
              data: (items) {
                final filteredItems = selectedCategory != null
                    ? items
                        .where((item) => item.category == selectedCategory)
                        .toList()
                    : items;

                if (filteredItems.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined,
                            size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'No items in wishlist',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: Text(
                          AppConstants.categoryEmojis[item.category] ?? '📦',
                          style: const TextStyle(fontSize: 24),
                        ),
                        title: Text(item.itemName),
                        subtitle: Text(item.category),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            if (item.id != null) {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Remove Item'),
                                  content: Text(
                                      'Remove ${item.itemName} from wishlist?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        ref
                                            .read(wishlistNotifierProvider
                                                .notifier)
                                            .deleteItem(item.id!);
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                '${item.itemName} removed from wishlist'),
                                            duration:
                                                const Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        'Remove',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: $err'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItemDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}

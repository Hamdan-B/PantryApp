import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/core/constants/app_constants.dart';
import 'package:pantry_app/presentation/providers/pantry_provider.dart';
import 'package:pantry_app/presentation/providers/auth_provider.dart';
import 'package:pantry_app/data/models/pantry_item_model.dart';

class PantryScreen extends ConsumerStatefulWidget {
  const PantryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends ConsumerState<PantryScreen> {
  String? selectedCategory;

  @override
  Widget build(BuildContext context) {
    final itemsAsyncValue = selectedCategory == null
        ? ref.watch(pantryItemsProvider)
        : ref.watch(pantryByCategoryProvider(selectedCategory!));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pantry'),
        elevation: 0,
      ),
      body: Column(
        children: [
          if (selectedCategory == null)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: AppConstants.pantryCategories.map((category) {
                  final emoji = AppConstants.categoryEmojis[category] ?? '';
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ElevatedButton(
                      onPressed: () =>
                          setState(() => selectedCategory = category),
                      child: Text('$emoji $category'),
                    ),
                  );
                }).toList(),
              ),
            ),
          if (selectedCategory != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => setState(() => selectedCategory = null),
                  ),
                  Expanded(
                    child: Text(
                      '$selectedCategory Items',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () =>
                        _showAddItemDialog(context, ref, selectedCategory!),
                  ),
                ],
              ),
            ),
          Expanded(
            child: itemsAsyncValue.when(
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shopping_cart,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('No items in pantry'),
                        if (selectedCategory != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: ElevatedButton(
                              onPressed: () => _showAddItemDialog(
                                  context, ref, selectedCategory!),
                              child: const Text('Add Item'),
                            ),
                          ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return PantryItemCard(
                      item: item,
                      onRemove: () =>
                          _showRemovePortionDialog(context, ref, item),
                      onAdd: () => _showAddPortionDialog(context, ref, item),
                      onDelete: () => _deleteItem(ref, item),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog(
      BuildContext context, WidgetRef ref, String category) {
    final weightController = TextEditingController();
    final priceController = TextEditingController();
    final selectedItem = ValueNotifier<String?>(null);

    final categoryItems = AppConstants.categoryItems[category] ?? [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder(
                valueListenable: selectedItem,
                builder: (context, item, child) {
                  return DropdownButton<String>(
                    value: item,
                    hint: const Text('Select item'),
                    isExpanded: true,
                    items: categoryItems
                        .map((i) => DropdownMenuItem(value: i, child: Text(i)))
                        .toList(),
                    onChanged: (value) => selectedItem.value = value,
                  );
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: weightController,
                decoration: InputDecoration(
                  labelText: 'Weight (${AppConstants.categoryUnits[category]})',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  prefixText: '\$ ',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final authState = ref.read(authStateProvider).value;
              final user = authState?.session?.user;
              if (user != null &&
                  selectedItem.value != null &&
                  weightController.text.isNotEmpty &&
                  priceController.text.isNotEmpty) {
                final item = PantryItemModel(
                  userId: user.id,
                  category: category,
                  name: selectedItem.value!,
                  weight: double.parse(weightController.text),
                  price: double.parse(priceController.text),
                  unit: AppConstants.categoryUnits[category] ?? 'grams',
                  createdAt: DateTime.now(),
                );
                try {
                  print('[PANTRY_SCREEN] Adding item: ${item.toJson()}');
                  await ref
                      .read(pantryNotifierProvider(user.id).notifier)
                      .addItem(item);
                  print('[PANTRY_SCREEN] Item add succeeded');
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Item added')));
                  }
                } catch (e) {
                  print('[PANTRY_SCREEN] Item add failed: $e');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to add item: $e')));
                  }
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showRemovePortionDialog(
      BuildContext context, WidgetRef ref, PantryItemModel item) {
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Portion'),
        content: TextField(
          controller: amountController,
          decoration: InputDecoration(
            labelText: 'Amount to remove (${item.unit})',
          ),
          keyboardType: TextInputType.number,
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
              if (amountController.text.isNotEmpty &&
                  item.id != null &&
                  user != null) {
                ref
                    .read(pantryNotifierProvider(user.id).notifier)
                    .removeItemPortion(
                        item.id!, double.parse(amountController.text));
                Navigator.pop(context);
              }
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showAddPortionDialog(
      BuildContext context, WidgetRef ref, PantryItemModel item) {
    final weightController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Portion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: weightController,
              decoration: InputDecoration(
                labelText: 'Weight (${item.unit})',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(
                labelText: 'Price',
                prefixText: '\$ ',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
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
              if (weightController.text.isNotEmpty &&
                  priceController.text.isNotEmpty &&
                  item.id != null &&
                  user != null) {
                ref
                    .read(pantryNotifierProvider(user.id).notifier)
                    .addItemPortion(
                        item.id!,
                        double.parse(weightController.text),
                        double.parse(priceController.text));
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _deleteItem(WidgetRef ref, PantryItemModel item) {
    final authState = ref.read(authStateProvider).value;
    final user = authState?.session?.user;
    if (item.id != null && user != null) {
      ref.read(pantryNotifierProvider(user.id).notifier).deleteItem(item.id!);
    }
  }
}

class PantryItemCard extends StatelessWidget {
  final PantryItemModel item;
  final VoidCallback onRemove;
  final VoidCallback onAdd;
  final VoidCallback onDelete;

  const PantryItemCard({
    Key? key,
    required this.item,
    required this.onRemove,
    required this.onAdd,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.weight} ${item.unit} | \$${item.price.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: const Text('Add'),
                      onTap: onAdd,
                    ),
                    PopupMenuItem(
                      child: const Text('Remove'),
                      onTap: onRemove,
                    ),
                    PopupMenuItem(
                      child: const Text('Delete',
                          style: TextStyle(color: Colors.red)),
                      onTap: onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

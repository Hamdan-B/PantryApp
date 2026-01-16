import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/presentation/providers/auth_provider.dart';
import 'package:pantry_app/presentation/providers/theme_provider.dart';
import 'package:pantry_app/presentation/screens/analytics/analytics_screen.dart';
import 'package:pantry_app/data/models/user_model.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final isDarkMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        elevation: 0,
      ),
      body: authState.when(
        data: (state) {
          final user = state.session?.user;
          if (user == null) {
            return const Center(child: Text('Not logged in'));
          }

          final userProfileAsync = ref.watch(userProfileProvider);

          return userProfileAsync.when(
            data: (userProfile) {
              final displayName = userProfile?.name ?? user.email ?? 'Unknown';
              final initial = (userProfile?.name?.isNotEmpty ?? false)
                  ? userProfile!.name![0].toUpperCase()
                  : (user.email?.isNotEmpty ?? false)
                      ? user.email![0].toUpperCase()
                      : 'U';

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.green,
                            child: Text(
                              initial,
                              style: const TextStyle(
                                  fontSize: 32, color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            displayName,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          if (userProfile?.name != null)
                            Text(
                              user.email ?? '',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    const Text(
                      'Settings',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: InkWell(
                        onTap: () =>
                            _showEditProfileDialog(context, ref, userProfile),
                        child: const Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.edit, color: Colors.orange),
                                  SizedBox(width: 12),
                                  Text(
                                    'Edit Profile',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                              Icon(Icons.arrow_forward_ios, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const AnalyticsScreen(),
                            ),
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.analytics, color: Colors.blue),
                                  SizedBox(width: 12),
                                  Text(
                                    'Analytics',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                              Icon(Icons.arrow_forward_ios, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Dark Mode'),
                            Switch(
                              value: isDarkMode,
                              onChanged: (value) {
                                ref
                                    .read(themeModeProvider.notifier)
                                    .setDarkMode(value);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: () {
                        ref.read(authNotifierProvider.notifier).signOut();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Logout',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading profile: $err'),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _showEditProfileDialog(
      BuildContext context, WidgetRef ref, UserModel? userProfile) {
    final nameController = TextEditingController(text: userProfile?.name ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'Enter your name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty && userProfile != null) {
                await ref
                    .read(userProfileNotifierProvider.notifier)
                    .updateUserName(userProfile.id, name);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Profile updated successfully')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

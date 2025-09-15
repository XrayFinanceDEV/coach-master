import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coachmaster/core/firebase_auth_providers.dart';

class FirebaseTestScreen extends ConsumerStatefulWidget {
  const FirebaseTestScreen({super.key});

  @override
  ConsumerState<FirebaseTestScreen> createState() => _FirebaseTestScreenState();
}

class _FirebaseTestScreenState extends ConsumerState<FirebaseTestScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isSignUp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(firebaseAuthProvider);
    final authNotifier = ref.read(firebaseAuthProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Auth Test'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Auth Status Display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Auth Status: ${authState.status.name}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (authState.isAuthenticated) ...[
                    Text('Email: ${authState.email ?? 'No email'}'),
                    Text('Display Name: ${authState.displayName ?? 'No name'}'),
                    Text('UID: ${authState.uid ?? 'No UID'}'),
                  ],
                  if (authState.hasError) ...[
                    Text(
                      'Error: ${authState.errorMessage}',
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                  if (authState.isLoadingState) ...[
                    const Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Loading...'),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Auth Forms
            if (!authState.isAuthenticated) ...[
              // Toggle between Sign In / Sign Up
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => setState(() => _isSignUp = false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !_isSignUp 
                          ? Theme.of(context).colorScheme.primary 
                          : Theme.of(context).colorScheme.surface,
                        foregroundColor: !_isSignUp 
                          ? Colors.white 
                          : Theme.of(context).colorScheme.onSurface,
                      ),
                      child: const Text('Sign In'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => setState(() => _isSignUp = true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isSignUp 
                          ? Theme.of(context).colorScheme.primary 
                          : Theme.of(context).colorScheme.surface,
                        foregroundColor: _isSignUp 
                          ? Colors.white 
                          : Theme.of(context).colorScheme.onSurface,
                      ),
                      child: const Text('Sign Up'),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Name field (only for sign up)
              if (_isSignUp) ...[
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Email field
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              
              const SizedBox(height: 16),
              
              // Password field
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              
              const SizedBox(height: 24),
              
              // Submit button
              ElevatedButton(
                onPressed: authState.isLoadingState 
                  ? null 
                  : () {
                      if (_isSignUp) {
                        authNotifier.registerWithEmail(
                          _emailController.text,
                          _passwordController.text,
                          _nameController.text,
                        );
                      } else {
                        authNotifier.signInWithEmail(
                          _emailController.text,
                          _passwordController.text,
                        );
                      }
                    },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(_isSignUp ? 'Sign Up' : 'Sign In'),
              ),
            ] else ...[
              // Signed in - show sign out button
              ElevatedButton(
                onPressed: () => authNotifier.signOut(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Sign Out'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
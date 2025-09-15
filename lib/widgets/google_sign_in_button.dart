import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coachmaster/core/auth_providers.dart';

class GoogleSignInButton extends ConsumerStatefulWidget {
  final VoidCallback? onSuccess;
  final void Function(String error)? onError;
  final String? text;
  final bool enabled;

  const GoogleSignInButton({
    super.key,
    this.onSuccess,
    this.onError,
    this.text,
    this.enabled = true,
  });

  @override
  ConsumerState<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends ConsumerState<GoogleSignInButton> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading || !widget.enabled) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authNotifierProvider.notifier).signInWithGoogle();
      widget.onSuccess?.call();
    } catch (e) {
      widget.onError?.call(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isAuthLoading = authState.isLoading;
    final isButtonLoading = _isLoading || isAuthLoading;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: (widget.enabled && !isButtonLoading) ? _handleGoogleSignIn : null,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline,
            width: 1.5,
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
        ),
        icon: isButtonLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              )
            : _buildGoogleIcon(),
        label: Text(
          isButtonLoading ? 'Signing in...' : (widget.text ?? 'Continue with Google'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleIcon() {
    // Google Logo SVG as a simple colored container
    // In a real app, you'd use the official Google logo SVG or PNG
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF4285F4), // Google Blue
            Color(0xFF34A853), // Google Green
            Color(0xFFFBBC05), // Google Yellow
            Color(0xFFEA4335), // Google Red
          ],
          stops: [0.25, 0.5, 0.75, 1.0],
        ),
      ),
      child: const Center(
        child: Text(
          'G',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// Alternative compact Google Sign-In button for smaller spaces
class CompactGoogleSignInButton extends ConsumerStatefulWidget {
  final VoidCallback? onSuccess;
  final void Function(String error)? onError;

  const CompactGoogleSignInButton({
    super.key,
    this.onSuccess,
    this.onError,
  });

  @override
  ConsumerState<CompactGoogleSignInButton> createState() => _CompactGoogleSignInButtonState();
}

class _CompactGoogleSignInButtonState extends ConsumerState<CompactGoogleSignInButton> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authNotifierProvider.notifier).signInWithGoogle();
      widget.onSuccess?.call();
    } catch (e) {
      widget.onError?.call(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _isLoading ? null : _handleGoogleSignIn,
      style: IconButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.surface,
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline,
        ),
        padding: const EdgeInsets.all(12),
      ),
      icon: _isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF4285F4),
                    Color(0xFF34A853),
                    Color(0xFFFBBC05),
                    Color(0xFFEA4335),
                  ],
                  stops: [0.25, 0.5, 0.75, 1.0],
                ),
              ),
              child: const Center(
                child: Text(
                  'G',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
      tooltip: 'Sign in with Google',
    );
  }
}
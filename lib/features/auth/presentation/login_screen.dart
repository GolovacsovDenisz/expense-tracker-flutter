import 'package:expense_tracker_fresh/features/auth/application/auth_providers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _controllerEmail = TextEditingController();
  final _controllerPassword = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _controllerEmail.addListener(_onChanged);
    _controllerPassword.addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controllerEmail.removeListener(_onChanged);
    _controllerPassword.removeListener(_onChanged);
    _controllerEmail.dispose();
    _controllerPassword.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    if (_isLoading) return false;
    final email = _controllerEmail.text.trim();
    final pass = _controllerPassword.text;
    return _isEmail(email) && _isPasswordOk(pass);
  }

  bool _isEmail(String v) {
    final r = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return r.hasMatch(v);
  }

  bool _isPasswordOk(String v) {
    return v.trim().length >= 8;
  }

  String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'The email is invalid. Check the format..';
      case 'user-not-found':
        return 'User not found. Register an account.';
      case 'wrong-password':
        return 'The password is incorrect.';
      case 'invalid-credential':
        return 'Incorrect data. Check email/password.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'There is a problem with the internet. Check your connection.';
      default:
        return e.message ?? 'Login error. Please try again.';
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).signInWithEmailPassword(
            email: _controllerEmail.text.trim(),
            password: _controllerPassword.text,
          );

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyAuthError(e))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _controllerEmail,
                  enabled: !_isLoading,
                  autocorrect: false,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    border: UnderlineInputBorder(),
                    labelText: 'Email',
                  ),
                  validator: (value) {
                    final v = (value ?? '').trim();
                    if (!_isEmail(v)) return 'Please enter a valid email address';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _controllerPassword,
                  enabled: !_isLoading,
                  autocorrect: false,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _canSubmit ? _submit() : null,
                  decoration: InputDecoration(
                    border: const UnderlineInputBorder(),
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      onPressed: _isLoading
                          ? null
                          : () => setState(() => _obscure = !_obscure),
                      icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                    ),
                  ),
                  validator: (value) {
                    final v = (value ?? '');
                    if (!_isPasswordOk(v)) return 'Password must be at least 8 characters long';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _canSubmit ? _submit : null,
                    child: _isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Sign in'),
                  ),
                ),
                TextButton(
                  onPressed: _isLoading ? null : () => context.go('/register'),
                  child: const Text('Create account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
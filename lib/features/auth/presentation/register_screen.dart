import 'package:expense_tracker_fresh/features/auth/application/auth_providers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
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
    return _isEmail(email) && _isPasswordStrong(pass);
  }

  bool _isEmail(String v) {
    final r = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return r.hasMatch(v);
  }

  bool _isPasswordStrong(String v) {

    if (v.trim().length < 8) return false;
    if (!RegExp(r'\d').hasMatch(v)) return false;
    return true;
  }

  String _passwordHint(String v) {
    if (v.trim().length < 8) return 'Minimum 8 characters and one number';
    if (!RegExp(r'\d').hasMatch(v)) return 'Add at least one number';
    return '';
  }

  String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered. Try logging in.';
      case 'invalid-email':
        return 'The email looks strange. Check the format..';
      case 'weak-password':
        return 'The password is too weak. Make it longer/more complex.';
      case 'network-request-failed':
        return 'There is a problem with the internet. Check your connection';
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
      await ref.read(authRepositoryProvider).registerWithEmailPassword(
            email: _controllerEmail.text.trim(),
            password: _controllerPassword.text,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created ✅')),
      );


      context.go('/home');
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
    final passHint = _passwordHint(_controllerPassword.text);

    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
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
                    helperText: passHint.isEmpty ? null : passHint,
                    suffixIcon: IconButton(
                      onPressed: _isLoading
                          ? null
                          : () => setState(() => _obscure = !_obscure),
                      icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                    ),
                  ),
                  validator: (value) {
                    final v = (value ?? '');
                    if (!_isPasswordStrong(v)) {
                      return 'Password: 8+ characters and at least 1 number';
                    }
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
                        : const Text('Register'),
                  ),
                ),
                TextButton(
                  onPressed: _isLoading ? null : () => context.go('/login'),
                  child: const Text('I already have an account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
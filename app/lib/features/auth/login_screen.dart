import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';

/// Two-step phone auth: enter number → enter the SMS code. On success the
/// caller's auth-state listener routes into the app.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.auth});

  final AuthService auth;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  String? _verificationId;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    await widget.auth.startPhoneAuth(
      phoneNumber: _phoneCtrl.text.trim(),
      onCodeSent: (id) => setState(() {
        _verificationId = id;
        _busy = false;
      }),
      onVerified: (_) => _finish(),
      onError: (e) => setState(() {
        _error = e.message;
        _busy = false;
      }),
    );
  }

  Future<void> _confirm() async {
    if (_verificationId == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.auth.confirmCode(
        verificationId: _verificationId!,
        smsCode: _codeCtrl.text.trim(),
      );
      await _finish();
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.message;
        _busy = false;
      });
    }
  }

  Future<void> _finish() async {
    await widget.auth.ensureProfile(
      name: _nameCtrl.text.trim().isEmpty ? 'Friend' : _nameCtrl.text.trim(),
    );
    // auth-state listener handles navigation.
  }

  @override
  Widget build(BuildContext context) {
    final codeStage = _verificationId != null;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.shield_moon, size: 72, color: Color(0xFFE53935)),
              const SizedBox(height: 12),
              Text('Welcome to Suraksha',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 32),
              if (!codeStage) ...[
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Your name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone (with country code, e.g. +91…)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _busy ? null : _sendCode,
                  child: _busy
                      ? const CircularProgressIndicator()
                      : const Text('Send code'),
                ),
              ] else ...[
                TextField(
                  controller: _codeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Enter the 6-digit code',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _busy ? null : _confirm,
                  child: _busy
                      ? const CircularProgressIndicator()
                      : const Text('Verify & continue'),
                ),
                TextButton(
                  onPressed: () => setState(() => _verificationId = null),
                  child: const Text('Change number'),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

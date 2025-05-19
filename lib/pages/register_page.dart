// lib/pages/register_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/bottom_nav_bar.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorText = null; });

    try {
      await FirebaseAuth.instance
        .createUserWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text.trim(),
        );
      // After successful registration, you can either navigate to home
      // or send the user back to login to confirm their credentials.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const BottomNavBar()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _errorText = e.message);
    } catch (e) {
      setState(() => _errorText = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Create Account',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  TextFormField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (v) => (v==null||!v.contains('@')) 
                      ? 'Enter a valid email' : null,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _passwordCtrl,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (v) => (v==null||v.length<6) 
                      ? 'Must be at least 6 characters' : null,
                  ),
                  const SizedBox(height: 24),

                  if (_errorText != null) ...[
                    Text(_errorText!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 12),
                  ],

                  ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    child: _isLoading
                      ? const SizedBox(width:20, height:20, child: CircularProgressIndicator(strokeWidth:2))
                      : const Text('Sign Up'),
                  ),

                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _isLoading
                      ? null
                      : () => Navigator.of(context).pop(),
                    child: const Text('Already have an account? Log in'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:easy_localization/easy_localization.dart';

import 'register_page.dart';
import '../widgets/bottom_nav_bar.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorText = null;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );
      _goToHome();
    } on FirebaseAuthException catch (e) {
      setState(() => _errorText = e.message);
    } catch (e) {
      setState(() => _errorText = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });
    try {
      if (kIsWeb) {
        await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
      } else {
        final googleUser = await GoogleSignIn(
          clientId: dotenv.env['GOOGLE_CLIENT_ID'],
        ).signIn();
        if (googleUser == null) return; // aborted

        final auth = await googleUser.authentication;
        final cred = GoogleAuthProvider.credential(
          accessToken: auth.accessToken,
          idToken: auth.idToken,
        );
        await FirebaseAuth.instance.signInWithCredential(cred);
      }
      _goToHome();
    } on FirebaseAuthException catch (e) {
      setState(() => _errorText = e.message);
    } catch (e) {
      setState(() => _errorText = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGitHub() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });
    try {
      final provider = GithubAuthProvider()..addScope('read:user');
      if (kIsWeb) {
        await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        await FirebaseAuth.instance.signInWithRedirect(provider);
        // On return, Firebase will complete the flow.
      }
      _goToHome();
    } on FirebaseAuthException catch (e) {
      setState(() => _errorText = e.message);
    } catch (e) {
      setState(() => _errorText = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const BottomNavBar()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'login_title'.tr(),
                        style: const TextStyle(
                          fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),

                      TextFormField(
                        controller: _emailCtrl,
                        decoration: InputDecoration(
                          labelText: 'email'.tr(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'enter_email'.tr();
                          }
                          if (!val.contains('@')) {
                            return 'invalid_email'.tr();
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _passwordCtrl,
                        decoration: InputDecoration(
                          labelText: 'password'.tr(),
                        ),
                        obscureText: true,
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'enter_password'.tr();
                          }
                          if (val.length < 6) {
                            return 'short_password'.tr();
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      if (_errorText != null) ...[
                        Text(
                          'auth_error'.tr(namedArgs: {'error': _errorText!}),
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                      ],

                      ElevatedButton(
                        onPressed: _isLoading ? null : _signInWithEmail,
                        child: _isLoading
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text('sign_in_email'.tr()),
                      ),
                      const SizedBox(height: 12),

                      ElevatedButton.icon(
                        icon: Image.asset(
                          'assets/google_logo.png',
                          height: 24, width: 24),
                        label: Text('sign_in_google'.tr()),
                        onPressed: _isLoading ? null : _signInWithGoogle,
                      ),
                      const SizedBox(height: 12),

                      ElevatedButton.icon(
                        icon: Image.asset(
                          'assets/github.png',
                          height: 24, width: 24),
                        label: Text('sign_in_github'.tr()),
                        onPressed: _isLoading ? null : _signInWithGitHub,
                      ),

                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const RegisterPage(),
                              ),
                            ),
                        child: Text('no_account'.tr()),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black45,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

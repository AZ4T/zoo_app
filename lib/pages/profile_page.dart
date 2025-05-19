import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';

import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final User? _user = FirebaseAuth.instance.currentUser;

  bool _isEditing = false;
  bool _isSaving = false;

  late String _name;
  late String _email;
  String _bio = "profile.default_bio".tr();

  File? _profileImage;
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _bioCtrl   = TextEditingController();

  _ProfilePageState()
      : _name  = FirebaseAuth.instance.currentUser?.displayName ?? "",
        _email = FirebaseAuth.instance.currentUser?.email       ?? "";

  @override
  void initState() {
    super.initState();
    _nameCtrl.text  = _name;
    _emailCtrl.text = _email;
    _bioCtrl.text   = _bio;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
      );
      if (picked != null) {
        setState(() => _profileImage = File(picked.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('profile.error_pick_image'.tr(args: ['${e}']))),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      // Optionally update Firebase user here...

      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _name      = _nameCtrl.text.trim();
        _email     = _emailCtrl.text.trim();
        _bio       = _bioCtrl.text.trim();
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('profile.saved'.tr())),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('profile.error_save'.tr(args: ['${e}']))),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _toggleEditing() {
    if (_isEditing) {
      _saveProfile();
    } else {
      setState(() => _isEditing = true);
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    if (_profileImage != null) {
      imageWidget = kIsWeb
          ? Image.network(_profileImage!.path, fit: BoxFit.cover)
          : Image.file(_profileImage!, fit: BoxFit.cover);
    } else if (_user?.photoURL != null) {
      imageWidget = Image.network(_user!.photoURL!, fit: BoxFit.cover);
    } else {
      imageWidget = const Icon(Icons.person, size: 100, color: Colors.grey);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('profile.title'.tr()),
        actions: [
          if (!_isSaving)
            IconButton(
              icon: Icon(_isEditing ? Icons.check : Icons.edit),
              tooltip: _isEditing
                  ? 'profile.tooltip_save'.tr()
                  : 'profile.tooltip_edit'.tr(),
              onPressed: _toggleEditing,
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'profile.tooltip_sign_out'.tr(),
            onPressed: _signOut,
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Avatar
              GestureDetector(
                onTap: _isEditing ? _pickImage : null,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey.shade300,
                  child: ClipOval(
                    child: SizedBox(
                      width: 120,
                      height: 120,
                      child: imageWidget,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Display user info if not editing
              if (!_isEditing) ...[
                Text(
                  _user?.displayName ?? _name,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  _user?.email ?? _email,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Divider(height: 32),
              ],

              // Editable form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      enabled: _isEditing,
                      decoration: InputDecoration(
                        labelText: 'profile.label_name'.tr(),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty)
                              ? 'profile.error_name_empty'.tr()
                              : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailCtrl,
                      enabled: _isEditing,
                      decoration: InputDecoration(
                        labelText: 'profile.label_email'.tr(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'profile.error_email_empty'.tr();
                        }
                        if (!v.contains('@')) {
                          return 'profile.error_email_invalid'.tr();
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _bioCtrl,
                      enabled: _isEditing,
                      decoration: InputDecoration(
                        labelText: 'profile.label_bio'.tr(),
                      ),
                      maxLines: 3,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty)
                              ? 'profile.error_bio_empty'.tr()
                              : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

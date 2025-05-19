import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();

  bool _isEditing = false;
  bool _isSaving  = false;

  String _name  = "John Doe";
  String _email = "johndoe@email.com";
  String _bio   = "Lover of animals and nature.";

  File? _profileImage;

  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _bioCtrl   = TextEditingController();

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
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Simulate saving delay (or save to your backend/local storage here)
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _name  = _nameCtrl.text.trim();
        _email = _emailCtrl.text.trim();
        _bio   = _bioCtrl.text.trim();
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _toggleEditing() {
    if (_isEditing) {
      _saveProfile();
    } else {
      setState(() {
        _isEditing = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    if (_profileImage != null) {
      imageWidget = kIsWeb
          ? Image.network(_profileImage!.path, fit: BoxFit.cover)
          : Image.file(_profileImage!, fit: BoxFit.cover);
    } else {
      imageWidget = const Icon(Icons.person, size: 100, color: Colors.grey);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              : IconButton(
                  icon: Icon(_isEditing ? Icons.check : Icons.edit),
                  onPressed: _toggleEditing,
                ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
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

                // Name
                TextFormField(
                  controller: _nameCtrl,
                  enabled: _isEditing,
                  decoration: const InputDecoration(labelText: "Name"),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? "Enter your name" : null,
                ),
                const SizedBox(height: 12),

                // Email
                TextFormField(
                  controller: _emailCtrl,
                  enabled: _isEditing,
                  decoration: const InputDecoration(labelText: "Email"),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return "Enter your email";
                    }
                    if (!v.contains('@')) {
                      return "Enter a valid email";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Bio
                TextFormField(
                  controller: _bioCtrl,
                  enabled: _isEditing,
                  decoration: const InputDecoration(labelText: "Bio"),
                  maxLines: 3,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? "Tell us something about yourself"
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

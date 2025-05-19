import 'dart:convert';
import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:image_picker_web/image_picker_web.dart';

import '../models/animal.dart';
import '../providers/animal_provider.dart';

class AddAnimalPage extends StatefulWidget {
  /// if non-null, we’re in “edit” mode
  final Animal? animal;

  /// the index into the box/list
  final int? index;

  const AddAnimalPage({Key? key, this.animal, this.index}) : super(key: key);

  @override
  _AddAnimalPageState createState() => _AddAnimalPageState();
}

class _AddAnimalPageState extends State<AddAnimalPage> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final breedController = TextEditingController();
  final priceController = TextEditingController();
  final descriptionController = TextEditingController();

  Uint8List? _pickedImageBytes;
  String? _base64Image;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.animal != null) {
      nameController.text = widget.animal!.name;
      breedController.text = widget.animal!.breed;
      priceController.text = widget.animal!.price.toString();
      descriptionController.text = widget.animal!.description;
      _base64Image = widget.animal!.imageBase64;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    breedController.dispose();
    priceController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImageWeb() async {
    try {
      final Uint8List? bytes = await ImagePickerWeb.getImageAsBytes();
      if (bytes != null && bytes.isNotEmpty) {
        setState(() {
          _pickedImageBytes = bytes;
          _base64Image = base64Encode(bytes);
        });
      }
    } catch (e, st) {
      debugPrint('Image pick error: $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('couldnt_pick_image'.tr(args: ['${e}']))),
      );
    }
  }

  Future<void> _saveAnimal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final provider = context.read<AnimalProvider>();

    final edited = Animal(
      name: nameController.text,
      breed: breedController.text,
      price: double.tryParse(priceController.text) ?? 0,
      description: descriptionController.text,
      imageUrl: widget.animal?.imageUrl ?? '',
      isLiked: widget.animal?.isLiked ?? false,
      imageBase64: _base64Image,
    );

    try {
      if (widget.index != null) {
        // EDIT case
        await provider.updateAnimal(widget.index!, edited);
      } else {
        // CREATE case
        await provider.addAnimal(edited);
      }
      Navigator.pop(context);
    } catch (e, st) {
      debugPrint('Save animal error: $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('couldnt_save_animal'.tr(args: ['${e}']))),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.index != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'edit_animal'.tr() : 'add_animal'.tr()),
      ),
      body: Stack(
        children: [
          // ——— The regular form ———
          Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'name'.tr(),
                    ),
                    validator: (val) => (val == null || val.isEmpty)
                        ? 'enter_name'.tr()
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: breedController,
                    decoration: InputDecoration(
                      labelText: 'breed'.tr(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: priceController,
                    decoration: InputDecoration(
                      labelText: 'price'.tr(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'description'.tr(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'upload_image'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickImageWeb,
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey),
                      ),
                      alignment: Alignment.center,
                      child: _pickedImageBytes != null
                          ? Image.memory(
                              _pickedImageBytes!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            )
                          : Text('tap_to_select_image'.tr()),
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveAnimal,
                    child: Text(isEditing ? 'update'.tr() : 'save'.tr()),
                  ),
                ],
              ),
            ),
          ),

          // ——— Blocking loading overlay ———
          if (_isSaving)
            const Positioned.fill(
              child: ModalBarrier(color: Colors.black45, dismissible: false),
            ),
          if (_isSaving)
            Center(
              child: Lottie.asset(
                'animations/loading.json',
                width: 150,
                height: 150,
              ),
            ),
        ],
      ),
    );
  }
}

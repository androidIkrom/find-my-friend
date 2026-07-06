import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import 'profile_cubit.dart';
import 'profile_state.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  late final TextEditingController _nameController;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: context.read<ProfileCubit>().state.name,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const Key('cameraOption'),
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            ListTile(
              key: const Key('galleryOption'),
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picked = await _picker.pickImage(source: source);
    if (picked == null) return;
    if (!mounted) return;
    context.read<ProfileCubit>().avatarSelected(File(picked.path));
  }

  ImageProvider? _avatarImage(ProfileState state) {
    if (state.avatarFile != null) return FileImage(state.avatarFile!);
    if (state.existingAvatarUrl != null) {
      return NetworkImage(state.existingAvatarUrl!);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set up your profile')),
      body: BlocConsumer<ProfileCubit, ProfileState>(
        listenWhen: (previous, current) =>
            previous.status != current.status &&
            (current.status == ProfileStatus.success ||
                current.status == ProfileStatus.failure),
        listener: (context, state) {
          if (state.status == ProfileStatus.success) {
            widget.onComplete();
          } else if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
        },
        builder: (context, state) {
          final image = _avatarImage(state);
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  key: const Key('avatarPicker'),
                  onTap: _pickAvatar,
                  child: CircleAvatar(
                    radius: 48,
                    backgroundImage: image,
                    child: image == null
                        ? const Icon(Icons.add_a_photo, size: 32)
                        : null,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  key: const Key('nameField'),
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Your name'),
                  onChanged: (value) =>
                      context.read<ProfileCubit>().nameChanged(value),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  key: const Key('continueButton'),
                  onPressed: state.status == ProfileStatus.submitting
                      ? null
                      : () => context.read<ProfileCubit>().submit(),
                  child: state.status == ProfileStatus.submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Continue'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

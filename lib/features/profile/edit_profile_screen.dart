import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'account_screen.dart';

import '../../core/state/soniq_controller.dart';
import '../../core/widgets/user_avatar.dart';
import '../../core/widgets/neon_scaffold.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _username;
  late final TextEditingController _bio;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!(_initialized)) {
      final state = SoniqScope.of(context);
      _name = TextEditingController(text: state.displayName);
      _username = TextEditingController(text: state.username);
      _bio = TextEditingController(text: state.bio);
      _initialized = true;
    }
  }

  bool _initialized = false;
  bool _uploading = false;

  Future<void> _pickAvatar() async {
    final state = SoniqScope.of(context);
    if (state.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Entre na sua conta para salvar a foto na nuvem.'),
      ));
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountScreen()));
      return;
    }
    final photo = await ImagePicker().pickImage(source: ImageSource.gallery,
      maxWidth: 1024, maxHeight: 1024, imageQuality: 82);
    if (photo == null || !mounted) return;
    setState(() => _uploading = true);
    try {
      final bytes = await photo.readAsBytes();
      final ext = photo.name.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
      await state.uploadAvatar(bytes, ext);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto de perfil atualizada!')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível enviar a foto: $error')));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    final state = SoniqScope.of(context);
    if (_name.text.trim().isEmpty || _username.text.trim().isEmpty) {
      showDemoMessage(context, 'Preencha seu nome e nome de usuário.');
      return;
    }
    try {
      await state.saveProfile(_name.text.trim(), _username.text.trim(), _bio.text.trim());
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível salvar o perfil: $error')));
    }
  }


  @override
  void dispose() {
    if (_initialized) { _name.dispose(); _username.dispose(); _bio.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = SoniqScope.of(context);
    return NeonScaffold(child: Column(children: [
      const PageTitle('Editar Perfil'),
      Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), children: [
        Center(child: Stack(clipBehavior: Clip.none, children: [
          Container(width: 103, height: 103, padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: state.accent, width: 2),
              boxShadow: [BoxShadow(color: state.accent.withOpacity(.3), blurRadius: 23)]),
            child: UserAvatar(url: state.avatarUrl, size: 91)),
          Positioned(right: -4, bottom: 0, child: CircleGlassButton(icon: Icons.edit_rounded, size: 34,
            onTap: _uploading ? () {} : () { _pickAvatar(); })),
        ])),
        const SizedBox(height: 30),
        _Field(label: 'Nome', controller: _name),
        _Field(label: 'Nome de usuário', controller: _username),
        _Field(label: 'Biografia', controller: _bio, maxLines: 2),
        const SizedBox(height: 15),
        _EditOption(icon: Icons.camera_alt_outlined, label: 'Alterar foto', onTap: _pickAvatar),
        if (state.avatarPath != null) _EditOption(icon: Icons.delete_outline, label: 'Remover foto', onTap: () async {
          try { await state.removeAvatar(); }
          catch (_) { if (mounted) showDemoMessage(context, 'Não foi possível remover a foto.'); }
        }),
        _EditOption(icon: Icons.image_outlined, label: 'Alterar capa de perfil', onTap: () => showDemoMessage(context, 'A personalização da capa chega em uma próxima atualização.')),
        const SizedBox(height: 28),
        NeonButton(label: state.profileSaving ? 'Salvando...' : 'Salvar alterações', onPressed: _save),
      ])),
    ]));
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.controller, this.maxLines = 1});
  final String label;
  final TextEditingController controller;
  final int maxLines;

  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 14), child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      const SizedBox(height: 7),
      TextField(controller: controller, maxLines: maxLines, maxLength: maxLines == 1 ? 40 : 130,
        style: const TextStyle(fontSize: 13), decoration: const InputDecoration(counterText: '')),
    ],
  ));
}

class _EditOption extends StatelessWidget {
  const _EditOption({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 9), child: GlassPanel(
    padding: const EdgeInsets.all(14),
    onTap: onTap,
    child: Row(children: [Icon(icon, size: 20), const SizedBox(width: 12), Expanded(child: Text(label, style: const TextStyle(fontSize: 13))), const Icon(Icons.chevron_right_rounded, size: 18)]),
  ));
}

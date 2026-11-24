import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/state/soniq_controller.dart';
import '../../core/widgets/neon_scaffold.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _fullName = TextEditingController();
  final _phone = TextEditingController();
  String _nationality = 'Brasil';
  bool _register = false;
  bool _busy = false;
  String? _message;

  @override
  void dispose() { _email.dispose(); _password.dispose(); _confirmPassword.dispose(); _fullName.dispose(); _phone.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_email.text.trim().isEmpty || _password.text.length < 6) {
      setState(() => _message = 'Informe um e-mail e uma senha de pelo menos 6 caracteres.');
      return;
    }
    if (_register) {
      final phoneDigits = _phone.text.replaceAll(RegExp(r'\D'), '');
      if (_fullName.text.trim().length < 3) {
        setState(() => _message = 'Informe seu nome completo.'); return;
      }
      if (phoneDigits.length < 10 || phoneDigits.length > 13) {
        setState(() => _message = 'Informe um telefone válido com DDD.'); return;
      }
      if (_password.text != _confirmPassword.text) {
        setState(() => _message = 'As senhas não coincidem.'); return;
      }
    }
    setState(() { _busy = true; _message = null; });
    try {
      final client = Supabase.instance.client;
      if (_register) {
        final result = await client.auth.signUp(
          email: _email.text.trim(), password: _password.text,
          data: {
            'full_name': _fullName.text.trim(),
            'phone': _phone.text.replaceAll(RegExp(r'\D'), ''),
            'nationality': _nationality,
          },
        );
        if (!mounted) return;
        if (result.session == null) {
          setState(() => _message = 'Cadastro enviado! Confira seu e-mail para confirmar a conta.');
        } else {
          final state = SoniqScope.of(context);
          await state.loadRemoteProfile();
          await state.initializeCatalog();
          if (mounted) Navigator.pop(context);
        }
      } else {
        await client.auth.signInWithPassword(email: _email.text.trim(), password: _password.text);
        if (!mounted) return;
        final state = SoniqScope.of(context);
          await state.loadRemoteProfile();
          await state.initializeCatalog();
        if (mounted) Navigator.pop(context);
      }
    } on AuthException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } catch (error) {
      if (mounted) setState(() => _message = 'Falha na conexão: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    setState(() => _busy = true);
    try {
      final state = SoniqScope.of(context);
      await Supabase.instance.client.auth.signOut();
      await state.resetAccount();
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) setState(() => _message = 'Não foi possível sair: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = SoniqScope.of(context);
    final user = state.currentUser;
    return NeonScaffold(child: SafeArea(child: ListView(padding: const EdgeInsets.all(24), children: [
      Row(children: [IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back)),
        const SizedBox(width: 12), const Text('Minha conta SONIQ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))]),
      const SizedBox(height: 30),
      const Icon(Icons.headphones_rounded, color: Color(0xFFB04DFF), size: 66),
      const SizedBox(height: 22),
      if (!state.cloudEnabled) const Text('Configure SUPABASE_URL e SUPABASE_ANON_KEY para ativar o login.', textAlign: TextAlign.center)
      else if (user != null) ...[
        const Text('Você está conectado!', textAlign: TextAlign.center, style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10), Text(user.email ?? '', textAlign: TextAlign.center),
        const SizedBox(height: 25), ElevatedButton(onPressed: _busy ? null : _signOut, child: const Text('Sair da conta')),
      ] else ...[
        Text(_register ? 'Criar conta' : 'Entrar no SONIQ', textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 22),
        if (_register) ...[
          TextField(controller: _fullName, textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Nome completo', prefixIcon: Icon(Icons.person_outline))),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(value: _nationality,
            decoration: const InputDecoration(labelText: 'Nacionalidade', prefixIcon: Icon(Icons.public)),
            items: ['Brasil', 'Portugal', 'Angola', 'Moçambique', 'Outra']
              .map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
            onChanged: (value) { if (value != null) setState(() => _nationality = value); }),
          const SizedBox(height: 12),
          TextField(controller: _phone, keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Telefone com DDD', hintText: '(81) 99999-9999',
              prefixIcon: Icon(Icons.phone_outlined))),
          const SizedBox(height: 12),
        ],
        TextField(controller: _email, keyboardType: TextInputType.emailAddress,
          autocorrect: false, decoration: const InputDecoration(labelText: 'E-mail', prefixIcon: Icon(Icons.email_outlined))),
        const SizedBox(height: 12),
        TextField(controller: _password, obscureText: true,
          decoration: const InputDecoration(labelText: 'Senha', prefixIcon: Icon(Icons.lock_outline))),
        if (_register) ...[
          const SizedBox(height: 12),
          TextField(controller: _confirmPassword, obscureText: true,
            decoration: const InputDecoration(labelText: 'Confirmar senha', prefixIcon: Icon(Icons.verified_user_outlined))),
        ],
        const SizedBox(height: 20),
        ElevatedButton(onPressed: _busy ? null : _submit,
          child: Text(_busy ? 'Aguarde...' : _register ? 'Criar conta' : 'Entrar')),
        TextButton(onPressed: _busy ? null : () => setState(() { _register = !_register; _message = null; }),
          child: Text(_register ? 'Já tenho uma conta' : 'Ainda não tenho conta')),
      ],
      if (_message != null) Padding(padding: const EdgeInsets.only(top: 20),
        child: Text(_message!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFFFB6D5)))),
    ])));
  }
}

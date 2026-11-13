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
  bool _register = false;
  bool _busy = false;
  String? _message;

  @override
  void dispose() { _email.dispose(); _password.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_email.text.trim().isEmpty || _password.text.length < 6) {
      setState(() => _message = 'Informe um e-mail e uma senha de pelo menos 6 caracteres.');
      return;
    }
    setState(() { _busy = true; _message = null; });
    try {
      final client = Supabase.instance.client;
      if (_register) {
        final result = await client.auth.signUp(email: _email.text.trim(), password: _password.text);
        if (!mounted) return;
        if (result.session == null) {
          setState(() => _message = 'Cadastro enviado! Confira seu e-mail para confirmar a conta.');
        } else {
          await SoniqScope.of(context).loadRemoteProfile();
          if (mounted) Navigator.pop(context);
        }
      } else {
        await client.auth.signInWithPassword(email: _email.text.trim(), password: _password.text);
        if (!mounted) return;
        await SoniqScope.of(context).loadRemoteProfile();
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
      await Supabase.instance.client.auth.signOut();
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
        TextField(controller: _email, keyboardType: TextInputType.emailAddress,
          autocorrect: false, decoration: const InputDecoration(labelText: 'E-mail', prefixIcon: Icon(Icons.email_outlined))),
        const SizedBox(height: 12),
        TextField(controller: _password, obscureText: true,
          decoration: const InputDecoration(labelText: 'Senha', prefixIcon: Icon(Icons.lock_outline))),
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

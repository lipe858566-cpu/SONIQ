import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/widgets/user_avatar.dart';

class CommentsScreen extends StatefulWidget {
  const CommentsScreen({super.key, required this.trackId});
  final String trackId;
  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final input = TextEditingController();
  final db = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> comments = load();
  bool busy = false;

  Future<List<Map<String, dynamic>>> load() async => List<Map<String, dynamic>>.from(await db.rpc('soniq_comments', params: {'song_id': widget.trackId}));

  Future<void> change({String? id}) async {
    if (busy) return;
    final body = input.text.trim();
    final user = db.auth.currentUser;
    if (user == null || (id == null && body.isEmpty)) return;
    setState(() => busy = true);
    try {
      if (id == null) {
        await db.from('track_comments').insert({'track_id': widget.trackId, 'user_id': user.id, 'body': body});
        input.clear();
      } else {
        await db.from('track_comments').delete().eq('id', id).eq('user_id', user.id);
      }
      if (mounted) setState(() => comments = load());
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível atualizar os comentários.')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() { input.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Comentários')), body: Column(children: [
    Expanded(child: FutureBuilder<List<Map<String, dynamic>>>(future: comments, builder: (context, snapshot) {
      if (snapshot.hasError) return Center(child: TextButton(onPressed: () => setState(() => comments = load()), child: const Text('Falha ao carregar. Tentar novamente')));
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
      final rows = snapshot.data!;
      if (rows.isEmpty) return const Center(child: Text('Nenhum comentário ainda.'));
      return ListView.builder(itemCount: rows.length, itemBuilder: (context, i) {
        final row = rows[i];
        final path = row['avatar_path'] as String?;
        return ListTile(leading: UserAvatar(url: path == null ? null : db.storage.from('avatars').getPublicUrl(path), size: 42), title: Text(row['display_name'] as String), subtitle: Text('${row['body']}\n${DateTime.parse(row['created_at'] as String).toLocal().toString().substring(0, 16)}'), trailing: row['user_id'] == db.auth.currentUser?.id ? IconButton(onPressed: busy ? null : () => change(id: row['id'] as String), icon: const Icon(Icons.delete_outline)) : null);
      });
    })),
    SafeArea(child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [Expanded(child: TextField(controller: input, maxLength: 1000, decoration: const InputDecoration(hintText: 'Escreva um comentário'))), IconButton(onPressed: busy ? null : () => change(), icon: const Icon(Icons.send))])))
  ]));
}

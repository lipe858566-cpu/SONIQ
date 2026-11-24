import 'package:flutter/material.dart';
import '../../core/audio/download_store.dart';
import '../../core/models/music_models.dart';

class DownloadButton extends StatefulWidget {
  const DownloadButton({super.key, required this.track});
  final Track track;
  @override
  State<DownloadButton> createState() => _DownloadButtonState();
}
class _DownloadButtonState extends State<DownloadButton> {
  final store = DownloadStore.instance;
  bool busy = false;
  double? progress;
  late Future<bool> saved = store.exists(widget.track.id);
  Future<void> toggle(bool downloaded) async {
    setState(() { busy = true; progress = null; });
    try {
      if (downloaded) { await store.remove(widget.track.id); }
      else { await store.save(widget.track, (value) { if (mounted) setState(() => progress = value); }); }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível concluir a operação.')));
    } finally {
      if (mounted) setState(() { busy = false; saved = store.exists(widget.track.id); });
    }
  }
  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(future: saved, builder: (context, snapshot) {
    if (busy) return LinearProgressIndicator(value: progress);
    final downloaded = snapshot.data == true;
    return TextButton.icon(onPressed: snapshot.hasData ? () => toggle(downloaded) : null, icon: Icon(downloaded ? Icons.delete_outline : Icons.download), label: Text(downloaded ? 'Remover download' : 'Baixar música'));
  });
}

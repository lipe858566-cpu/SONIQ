import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/music_models.dart';

class DownloadStore {
  static final instance = DownloadStore();
  final active = <String>{};

  Future<File> fileFor(String id) async {
    final user = Supabase.instance.client.auth.currentUser?.id;
    if (user == null || !RegExp(r'^[a-fA-F0-9-]{36}$').hasMatch(id)) throw StateError('Conta ou faixa inválida');
    final root = await const MethodChannel('soniq/native').invokeMethod<String>('filesDir');
    if (root == null) throw StateError('Armazenamento indisponível');
    return File('$root/downloads/$user/$id.audio');
  }

  Future<bool> exists(String id) async => (await fileFor(id)).exists();

  Future<void> remove(String id) async {
    if (active.contains(id)) throw StateError('Download em andamento');
    final file = await fileFor(id);
    if (await file.exists()) await file.delete();
    final metadata = File('${file.path}.json');
    if (await metadata.exists()) await metadata.delete();
  }

  Future<List<Track>> restore() async {
    final root = (await fileFor('00000000-0000-0000-0000-000000000000')).parent;
    if (!await root.exists()) return [];
    final tracks = <Track>[];
    await for (final entry in root.list()) {
      if (entry is! File || !entry.path.endsWith('.audio.json')) continue;
      try {
        final data = jsonDecode(await entry.readAsString()) as Map<String, dynamic>;
        final file = await fileFor(data['id'] as String);
        if (!await file.exists()) continue;
        tracks.add(Track(id:data['id'],title:data['title'],artist:data['artist'],duration:data['duration'],cover:data['cover'],genre:data['genre'],album:data['album'],artworkUrl:data['artworkUrl'],lyrics:data['lyrics'],audioUrl:file.uri.toString()));
      } catch (_) {}
    }
    return tracks;
  }

  Future<void> save(Track track, void Function(double?) progress) async {
    if (!active.add(track.id)) throw StateError('Download em andamento');
    final client = http.Client();
    File? temporary;
    IOSink? sink;
    try {
      final target = await fileFor(track.id);
      await target.parent.create(recursive: true);
      final partial = File('${target.path}.part');
      temporary = partial;
      final response = await client.send(http.Request('GET', Uri.parse(track.audioUrl!)));
      if (response.statusCode != 200) throw HttpException('HTTP ${response.statusCode}');
      final output = partial.openWrite();
      sink = output;
      var received = 0;
      await for (final chunk in response.stream.timeout(const Duration(seconds: 30))) {
        received += chunk.length;
        if (received > 104857600) throw StateError('Arquivo muito grande');
        output.add(chunk);
        progress(response.contentLength == null || response.contentLength == 0 ? null : received / response.contentLength!);
      }
      await output.close();
      sink = null;
      if (received == 0 || (response.contentLength != null && received != response.contentLength)) throw StateError('Arquivo incompleto');
      await partial.rename(target.path);
      await File('${target.path}.json').writeAsString(jsonEncode({'id':track.id,'title':track.title,'artist':track.artist,'duration':track.duration,'cover':track.cover,'genre':track.genre,'album':track.album,'artworkUrl':track.artworkUrl,'lyrics':track.lyrics}));
    } finally {
      client.close();
      active.remove(track.id);
      await sink?.close();
      if (temporary != null && await temporary.exists()) await temporary.delete();
    }
  }
}

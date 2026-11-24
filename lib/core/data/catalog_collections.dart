import '../models/music_models.dart';

class CatalogCollections {
  static const tracks = <Track>[];

  static final playlists = <MusicPlaylist>[
    MusicPlaylist(id: 'favorites', title: 'Favoritos', cover: 'assets/covers/focus.jpg', trackIds: []),
    MusicPlaylist(id: 'academy', title: 'Academia', cover: 'assets/covers/academy.jpg', trackIds: []),
    MusicPlaylist(id: 'travel', title: 'Viagem', cover: 'assets/covers/road_trip.jpg', trackIds: []),
    MusicPlaylist(id: 'focus', title: 'Foco', cover: 'assets/covers/focus.jpg', trackIds: []),
    MusicPlaylist(id: 'party', title: 'Festa', cover: 'assets/covers/party.jpg', trackIds: []),
    MusicPlaylist(id: 'electronic', title: 'Eletrônicas', cover: 'assets/genres/electronic.jpg', trackIds: []),
  ];

  static const genres = <MusicGenre>[
    MusicGenre('Eletrônica', 'assets/genres/electronic.jpg'),
    MusicGenre('Sertanejo', 'assets/genres/sertanejo.jpg'),
    MusicGenre('Trap', 'assets/genres/trap.jpg'),
    MusicGenre('Pop', 'assets/genres/pop.jpg'),
    MusicGenre('Rap', 'assets/genres/rap.jpg'),
    MusicGenre('Rock', 'assets/genres/rock.jpg'),
  ];
}

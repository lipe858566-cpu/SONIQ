import '../models/music_models.dart';

/// Local sample content. Replace with repository data after connecting an API.
class DemoCatalog {
  static const tracks = <Track>[
    Track(id: 'blinding', title: 'Blinding Lights', artist: 'The Weeknd', duration: '3:42', cover: 'assets/covers/astronaut.jpg', genre: 'Pop'),
    Track(id: 'afterhours', title: 'After Hours', artist: 'The Weeknd', duration: '6:01', cover: 'assets/covers/after_hours.jpg', genre: 'Pop'),
    Track(id: 'saveyourtears', title: 'Save Your Tears', artist: 'The Weeknd', duration: '3:35', cover: 'assets/covers/after_hours.jpg', genre: 'Pop'),
    Track(id: 'starboy', title: 'Starboy', artist: 'The Weeknd', duration: '3:50', cover: 'assets/covers/party.jpg', genre: 'Eletrônica'),
    Track(id: 'diewithasmile', title: 'Die With A Smile', artist: 'Bruno Mars', duration: '4:11', cover: 'assets/covers/road_trip.jpg', genre: 'Pop'),
    Track(id: 'creepin', title: 'Creepin\'', artist: 'Metro Boomin', duration: '3:52', cover: 'assets/genres/rap.jpg', genre: 'Rap'),
    Track(id: 'sunset', title: 'Sunset Drive', artist: 'Elektronomia', duration: '3:24', cover: 'assets/covers/road_trip.jpg', genre: 'Eletrônica'),
    Track(id: 'roadtrip', title: 'Road Trip', artist: 'NCS', duration: '3:16', cover: 'assets/covers/road_trip.jpg', genre: 'Eletrônica'),
    Track(id: 'ontheroad', title: 'On The Road', artist: 'The Weeknd', duration: '4:02', cover: 'assets/covers/after_hours.jpg', genre: 'Pop'),
    Track(id: 'endless', title: 'Endless Journey', artist: 'Avicii', duration: '3:57', cover: 'assets/covers/party.jpg', genre: 'Eletrônica'),
    Track(id: 'highway', title: 'Highway', artist: 'Kygo', duration: '4:21', cover: 'assets/covers/academy.jpg', genre: 'Eletrônica'),
    Track(id: 'midnight', title: 'Midnight City', artist: 'M83', duration: '4:03', cover: 'assets/covers/focus.jpg', genre: 'Eletrônica'),
  ];

  static final playlists = <MusicPlaylist>[
    MusicPlaylist(id: 'favorites', title: 'Favoritos', cover: 'assets/covers/focus.jpg', trackIds: ['blinding', 'afterhours'], displayCount: 128),
    MusicPlaylist(id: 'academy', title: 'Academia', cover: 'assets/covers/academy.jpg', trackIds: ['starboy', 'blinding', 'highway'], displayCount: 42),
    MusicPlaylist(id: 'travel', title: 'Viagem', cover: 'assets/covers/road_trip.jpg', trackIds: ['sunset', 'roadtrip', 'ontheroad', 'endless', 'highway'], displayCount: 87),
    MusicPlaylist(id: 'focus', title: 'Foco', cover: 'assets/covers/focus.jpg', trackIds: ['midnight', 'saveyourtears'], displayCount: 56),
    MusicPlaylist(id: 'party', title: 'Festa', cover: 'assets/covers/party.jpg', trackIds: ['starboy', 'endless', 'sunset'], displayCount: 68),
    MusicPlaylist(id: 'electronic', title: 'Eletrônicas', cover: 'assets/genres/electronic.jpg', trackIds: ['sunset', 'roadtrip', 'highway'], displayCount: 91),
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

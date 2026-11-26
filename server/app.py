from flask import Flask, request, jsonify
from flask_cors import CORS
import yt_dlp

app = Flask(__name__)
CORS(app)

@app.route('/search', methods=['GET'])
def search():
    query = request.args.get('q', '')

    if not query:
        return jsonify({'error': 'Busca vazia'}), 400

    try:
        # Sem limite fixo — busca até 50 resultados
        ydl_opts = {
            'format': 'bestaudio/best',
            'default_search': "ytsearch50",  # ← máximo 50 por busca
            'quiet': True,
            'no_warnings': True,
            'extract_flat': True,
        }

        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            results = ydl.extract_info(f"ytsearch50:{query}", download=False)
            
            tracks = []
            for entry in results.get('entries', []):
                tracks.append({
                    'id': entry.get('id'),
                    'title': entry.get('title'),
                    'artist': entry.get('channel', 'Desconhecido'),
                    'duration': entry.get('duration', 0),
                    'thumbnail': entry.get('thumbnails', [{}])[0].get('url', '') if entry.get('thumbnails') else '',
                    'url': f"https://www.youtube.com/watch?v={entry.get('id')}"
                })

            return jsonify({'results': tracks, 'count': len(tracks)})

    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/stream', methods=['GET'])
def get_stream():
    video_url = request.args.get('url', '')
    if not video_url:
        return jsonify({'error': 'URL vazia'}), 400

    try:
        ydl_opts = {
            'format': 'bestaudio[ext=m4a]/bestaudio',
            'quiet': True,
            'no_warnings': True,
        }

        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(video_url, download=False)
            audio_url = info['url']
            return jsonify({'audio_url': audio_url})

    except Exception as e:
        return jsonify({'error': str(e)}), 500


if __name__ == '__main__':
    print("🎵 Servidor SONIQ rodando em http://localhost:5000")
    app.run(host='0.0.0.0', port=5000, debug=True)

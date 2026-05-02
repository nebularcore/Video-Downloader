import yt_dlp

def get_video_info(url):
    ydl_opts = {'quiet': True, 'noplaylist': True}
    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        info = ydl.extract_info(url, download=False)
        formats = []
        for f in info.get('formats', []):
            if f.get('height') and f.get('vcodec') != 'none':
                formats.append({
                    'id': f['format_id'],
                    'res': f"{f['height']}p",
                    'ext': f.get('ext', 'mp4')
                })
        return formats, info.get('title', 'video')

def download_video(url, format_id, output_path):
    ydl_opts = {
        'format': f"{format_id}+bestaudio/best",
        'outtmpl': output_path,
        'merge_output_format': 'mp4',
        'quiet': True,
        'fixup': 'detect_or_warn'
    }
    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        ydl.download([url])
      

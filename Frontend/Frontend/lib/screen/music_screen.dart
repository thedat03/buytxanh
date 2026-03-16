import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:just_audio/just_audio.dart';
import 'dart:ui';

class MusicScreen extends StatefulWidget {
  @override
  _MusicScreenState createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  final TextEditingController _searchController = TextEditingController();
  List _tracks = [];
  final AudioPlayer _player = AudioPlayer();
  bool _isLoading = false;
  String _error = '';

  int? _currentIndex; // Lưu index bài hát đang phát
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  bool _isShuffle = false;
  bool _isRepeat = false;

  @override
  void initState() {
    super.initState();
    _player.positionStream.listen((pos) {
      setState(() {
        _position = pos;
      });
    });
    _player.durationStream.listen((dur) {
      setState(() {
        _duration = dur ?? Duration.zero;
      });
    });
    _player.playerStateStream.listen((state) {
      setState(() {
        _isPlaying = state.playing;
      });
    });
  }

  Future<void> searchTracks(String query) async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    final clientId = 'a564fba5';
    final url =
        'https://api.jamendo.com/v3.0/tracks/?client_id=$clientId&format=json&limit=20&search=$query';
    try {
      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);
      setState(() {
        _tracks = data['results'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Lỗi khi tìm kiếm nhạc.';
        _isLoading = false;
      });
    }
  }

  Future<void> playTrack(int index) async {
    final url = _tracks[index]['audio'];
    await _player.setUrl(url);
    _player.play();
    setState(() {
      _currentIndex = index;
    });
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _player.pause();
    } else {
      _player.play();
    }
  }

  void _playNext() {
    if (_tracks.isEmpty) return;
    int next = (_currentIndex ?? 0) + 1;
    if (next >= _tracks.length) next = 0;
    playTrack(next);
  }

  void _playPrevious() {
    if (_tracks.isEmpty) return;
    int prev = (_currentIndex ?? 0) - 1;
    if (prev < 0) prev = _tracks.length - 1;
    playTrack(prev);
  }

  void _toggleShuffle() {
    setState(() {
      _isShuffle = !_isShuffle;
    });
  }

  void _toggleRepeat() {
    setState(() {
      _isRepeat = !_isRepeat;
      _player.setLoopMode(_isRepeat ? LoopMode.one : LoopMode.off);
    });
  }

  void _seek(double value) {
    _player.seek(Duration(seconds: value.toInt()));
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color mainBg = Color(0xFFF4F9FF); // nền trắng xanh nhạt
    final Color accent = Color(0xFF4FC3F7); // xanh nhạt
    final Color textMain = Color(0xFF222B45); // xám đậm
    final Color textSub = Color(0xFF6A7BA2); // xám nhạt
    return Scaffold(
      appBar: _currentIndex == null
          ? PreferredSize(
              preferredSize: Size.fromHeight(70),
              child: AppBar(
                automaticallyImplyLeading: false,
                elevation: 0,
                flexibleSpace: SafeArea(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.12),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withOpacity(0.15),
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.all(8),
                            child: Icon(Icons.arrow_back, color: accent, size: 28),
                          ),
                        ),
                        SizedBox(width: 16),
                        Icon(Icons.music_note, color: accent, size: 32),
                        SizedBox(width: 12),
                        Text(
                          'Nghe nhạc',
                          style: TextStyle(
                            color: textMain,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                backgroundColor: mainBg,
              ),
            )
          : null,
      body: Stack(
        children: [
          if (_currentIndex == null)
            Container(
              color: mainBg,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Material(
                      elevation: 6,
                      borderRadius: BorderRadius.circular(30),
                      shadowColor: accent.withOpacity(0.08),
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(fontSize: 18, color: textMain),
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm bài hát, nghệ sĩ... ',
                          hintStyle: TextStyle(color: textSub),
                          prefixIcon: Icon(Icons.search, color: accent, size: 28),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(color: Colors.transparent),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(color: accent, width: 2),
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, color: Colors.redAccent),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() { _tracks = []; });
                                  },
                                )
                              : null,
                        ),
                        onSubmitted: searchTracks,
                      ),
                    ),
                  ),
                  if (_isLoading) CircularProgressIndicator(color: accent),
                  if (_error.isNotEmpty) Text(_error, style: TextStyle(color: Colors.red)),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _tracks.length,
                      itemBuilder: (context, index) {
                        final track = _tracks[index];
                        return ListTile(
                          leading: track['album_image'] != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(track['album_image'], width: 48, height: 48, fit: BoxFit.cover),
                                )
                              : Icon(Icons.music_note, color: accent),
                          title: Text(track['name'] ?? '', style: TextStyle(color: textMain)),
                          subtitle: Text(track['artist_name'] ?? '', style: TextStyle(color: textSub)),
                          trailing: IconButton(
                            icon: Icon(Icons.play_arrow, color: accent),
                            onPressed: () => playTrack(index),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            )
          else ...[
            _buildPlayer(
              mainBg: Colors.transparent,
              accent: accent,
              textMain: textMain,
              textSub: textSub,
            ),
            Positioned(
              top: 36,
              left: 16,
              child: GestureDetector(
                onTap: () => setState(() { _currentIndex = null; _player.stop(); }),
                child: Container(
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.15),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accent.withOpacity(0.18),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(10),
                  child: Icon(Icons.arrow_back, color: accent, size: 28),
                ),
              ),
            ),
          ],
        ],
      ),
      backgroundColor: mainBg,
    );
  }

  Widget _buildPlayer({Color? mainBg, Color? accent, Color? textMain, Color? textSub}) {
    if (_currentIndex == null) return SizedBox.shrink();
    final track = _tracks[_currentIndex!];
    final imageUrl = track['album_image'] ?? '';
    return Stack(
      children: [
        if (imageUrl.isNotEmpty)
          Positioned.fill(
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              color: accent?.withOpacity(0.08) ?? Colors.blue.withOpacity(0.08),
              colorBlendMode: BlendMode.lighten,
            ),
          ),
        if (imageUrl.isNotEmpty)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(color: mainBg?.withOpacity(0.85) ?? Colors.white.withOpacity(0.85)),
            ),
          ),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  imageUrl,
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    width: 200,
                    height: 200,
                    color: accent?.withOpacity(0.1) ?? Colors.blue.withOpacity(0.1),
                    child: Icon(Icons.music_note, size: 100, color: accent ?? Colors.blue),
                  ),
                ),
              ),
              SizedBox(height: 24),
              Text(
                track['name'] ?? '',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                track['artist_name'] ?? '',
                style: TextStyle(fontSize: 16, color: textSub ?? Colors.black54),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              Slider(
                value: _position.inSeconds.toDouble().clamp(0, _duration.inSeconds.toDouble()),
                min: 0,
                max: _duration.inSeconds.toDouble() > 0 ? _duration.inSeconds.toDouble() : 1,
                onChanged: _seek,
                activeColor: accent ?? Colors.blue,
                inactiveColor: (accent ?? Colors.blue).withOpacity(0.2),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatDuration(_position), style: TextStyle(color: textSub ?? Colors.black54)),
                    Text(_formatDuration(_duration), style: TextStyle(color: textSub ?? Colors.black54)),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.repeat, color: _isRepeat ? accent ?? Colors.blue : textSub ?? Colors.black54),
                    onPressed: _toggleRepeat,
                    iconSize: 28,
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.skip_previous, color: accent ?? Colors.blue),
                    onPressed: _playPrevious,
                    iconSize: 40,
                  ),
                  SizedBox(width: 8),
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: accent ?? Colors.blue,
                    child: IconButton(
                      icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 40),
                      onPressed: _togglePlayPause,
                    ),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.skip_next, color: accent ?? Colors.blue),
                    onPressed: _playNext,
                    iconSize: 40,
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.shuffle, color: _isShuffle ? accent ?? Colors.blue : textSub ?? Colors.black54),
                    onPressed: _toggleShuffle,
                    iconSize: 28,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final m = twoDigits(d.inMinutes.remainder(60));
    final s = twoDigits(d.inSeconds.remainder(60));
    return '$m:$s';
  }
} 
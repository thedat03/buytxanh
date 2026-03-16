import 'package:flutter/material.dart';
import 'music_screen.dart';
import 'game_screen.dart';

class EntertainmentScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Color accent = Color(0xFF4FC3F7);
    return Scaffold(
      appBar: AppBar(title: Text('Giải trí')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MusicScreen()),
                      );
                    },
                    child: Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withOpacity(0.08),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.music_note, color: accent, size: 48),
                          SizedBox(height: 12),
                          Text('Nghe nhạc', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: accent)),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 24),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => GameScreen()),
                      );
                    },
                    child: Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.13),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.08),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.videogame_asset, color: Colors.green, size: 48),
                          SizedBox(height: 12),
                          Text('Trò chơi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green[700])),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 32),
            // Chỗ này để bạn dễ dàng thêm các khối giải trí khác trong tương lai
            // Expanded(
            //   child: ListView(
            //     children: [
            //       // Thêm các mục khác ở đây
            //     ],
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
} 
import 'package:flutter/material.dart';

class GameScreen extends StatefulWidget {
  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  List<String> _board = List.filled(9, '');
  String _currentPlayer = 'X';
  String? _winner;

  @override
  void initState() {
    super.initState();
  }

  void _handleTap(int index) {
    if (_board[index] != '' || _winner != null || _currentPlayer != 'X') return;
    setState(() {
      _board[index] = 'X';
      _winner = _checkWinner();
      if (_winner == null) {
        _currentPlayer = 'O';
      }
    });
    if (_winner == null) {
      Future.delayed(Duration(milliseconds: 400), _aiMove);
    }
  }

  void _aiMove() {
    if (_winner != null || _currentPlayer != 'O') return;
    int bestScore = -1000;
    int move = -1;
    for (int i = 0; i < 9; i++) {
      if (_board[i] == '') {
        _board[i] = 'O';
        int score = _minimax(_board, 0, false);
        _board[i] = '';
        if (score > bestScore) {
          bestScore = score;
          move = i;
        }
      }
    }
    if (move != -1) {
      setState(() {
        _board[move] = 'O';
        _winner = _checkWinner();
        if (_winner == null) {
          _currentPlayer = 'X';
        }
      });
    }
  }

  int _minimax(List<String> board, int depth, bool isMaximizing) {
    String? result = _checkWinnerForMinimax(board);
    if (result != null) {
      if (result == 'O') return 10 - depth;
      if (result == 'X') return depth - 10;
      if (result == 'Hòa') return 0;
    }
    if (isMaximizing) {
      int bestScore = -1000;
      for (int i = 0; i < 9; i++) {
        if (board[i] == '') {
          board[i] = 'O';
          int score = _minimax(board, depth + 1, false);
          board[i] = '';
          if (score > bestScore) bestScore = score;
        }
      }
      return bestScore;
    } else {
      int bestScore = 1000;
      for (int i = 0; i < 9; i++) {
        if (board[i] == '') {
          board[i] = 'X';
          int score = _minimax(board, depth + 1, true);
          board[i] = '';
          if (score < bestScore) bestScore = score;
        }
      }
      return bestScore;
    }
  }

  String? _checkWinner() {
    return _checkWinnerForMinimax(_board);
  }

  String? _checkWinnerForMinimax(List<String> board) {
    const winPatterns = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8],
      [0, 3, 6], [1, 4, 7], [2, 5, 8],
      [0, 4, 8], [2, 4, 6],
    ];
    for (var pattern in winPatterns) {
      final a = pattern[0], b = pattern[1], c = pattern[2];
      if (board[a] != '' && board[a] == board[b] && board[a] == board[c]) {
        return board[a];
      }
    }
    if (!board.contains('')) return 'Hòa';
    return null;
  }

  void _resetGame() {
    setState(() {
      _board = List.filled(9, '');
      _currentPlayer = 'X';
      _winner = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cờ Caro với AI (Thông minh)'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _resetGame,
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _winner != null
                  ? (_winner == 'Hòa' ? 'Hòa!' : (_winner == 'X' ? 'Bạn thắng!' : 'AI thắng!'))
                  : (_currentPlayer == 'X' ? 'Lượt của bạn (X)' : 'Lượt của AI (O)'),
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            Container(
              width: 300,
              height: 300,
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: 9,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _handleTap(index),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blueAccent, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          _board[index],
                          style: TextStyle(
                            fontSize: 48,
                            color: _board[index] == 'X' ? Colors.blue : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              icon: Icon(Icons.refresh),
              label: Text('Chơi lại'),
              onPressed: _resetGame,
            ),
          ],
        ),
      ),
    );
  }
}

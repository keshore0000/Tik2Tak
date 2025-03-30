import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'game_service.dart';

class GameScreen extends StatefulWidget {
  final String gameCode;
  const GameScreen({super.key, required this.gameCode});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final GameService _gameService = GameService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String _currentPlayerId;
  late List<String> _localBoard;
  bool _isMakingMove = false;

  @override
  void initState() {
    super.initState();
    _currentPlayerId = _auth.currentUser!.uid;
    _localBoard = List.filled(9, '');
  }

  void _makeMove(int index) async {
    if (_isMakingMove) return;
    _isMakingMove = true;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('games')
          .doc(widget.gameCode)
          .get();

      final gameData = doc.data() as Map<String, dynamic>;

      if (gameData['currentTurn'] == _currentPlayerId &&
          gameData['status'] == 'playing') {
        setState(() {
          _localBoard[index] =
              _currentPlayerId == gameData['player1'] ? 'X' : 'O';
        });
        final batch = FirebaseFirestore.instance.batch();
        final gameRef =
            FirebaseFirestore.instance.collection('games').doc(widget.gameCode);
        batch.update(gameRef, {
          'boardState': _localBoard,
          'currentTurn': gameData['player1'] == _currentPlayerId
              ? gameData['player2']
              : gameData['player1'],
        });

        await batch.commit();
        _checkWinner(_localBoard);
      }
    } catch (e) {
      setState(() {
        _localBoard[index] = '';
      });
      print('move error: $e');
    } finally {
      _isMakingMove = false;
    }
  }

  void _checkWinner(List<String> board) async {
    const winPatterns = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], // Rows
      [0, 3, 6], [1, 4, 7], [2, 5, 8], // Columns
      [0, 4, 8], [2, 4, 6], // Diagonals
    ];

    String? winner;

    for (var pattern in winPatterns) {
      if (board[pattern[0]].isNotEmpty &&
          board[pattern[0]] == board[pattern[1]] &&
          board[pattern[1]] == board[pattern[2]]) {
        winner = board[pattern[0]];
        break;
      }
    }

    final isDraw = !board.contains("") && winner == null;

    await FirebaseFirestore.instance
        .collection('games')
        .doc(widget.gameCode)
        .update({
      'winner': winner ?? '',
      'status': isDraw ? 'draw' : (winner != null ? 'finished' : 'playing'),
    });
  }

  void _resetGame() async {
    await FirebaseFirestore.instance
        .collection('games')
        .doc(widget.gameCode)
        .update({
      'boardState': List.filled(9, ''),
      'currentTurn': _currentPlayerId,
      'winner': '',
      'status': 'playing',
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _gameService.gameStream(widget.gameCode),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final gameData = snapshot.data!.data() as Map<String, dynamic>;
        final board = List<String>.from(gameData['boardState']);
        final winner = gameData['winner'] as String;
        final isTie = gameData['status'] == 'draw';
        final currentTurn = gameData['currentTurn'] as String;
        final player1 = gameData['player1'] as String;
        final player2 = gameData['player2'] as String;

        final showReset = winner.isNotEmpty || isTie;

        if (snapshot.hasData) {
          final firestoreBoard = List<String>.from(gameData['boardState']);
          if (!listEquals(_localBoard, firestoreBoard)) {
            _localBoard = List.from(firestoreBoard);
          }
        }

        return _buildGameUI(
          context: context,
          board: _localBoard,
          winner: winner,
          isTie: isTie,
          currentTurn: currentTurn,
          player1: player1,
          player2: player2,
          showReset: showReset,
        );
      },
    );
  }

  Widget _buildGameUI({
    required BuildContext context,
    required List<String> board,
    required String winner,
    required bool isTie,
    required String currentTurn,
    required String player1,
    required String player2,
    required bool showReset,
  }) {
    Size size = MediaQuery.of(context).size;
    final isCurrentPlayer = currentTurn == _currentPlayerId;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple, Colors.red],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.8,
                colors: [Colors.transparent, Colors.black45],
              ),
            ),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Text('Game Code: ${widget.gameCode}'),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            body: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _PlayerCard(
                      label: "PLAYER 1 (X)",
                      isActive: currentTurn == player1,
                      isYou: _currentPlayerId == player1,
                      color: Colors.blueAccent,
                    ),
                    SizedBox(width: size.width * 0.08),
                    const Text(
                      "VS",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w300,
                        color: Colors.tealAccent,
                      ),
                    ),
                    SizedBox(width: size.width * 0.08),
                    _PlayerCard(
                      label: "PLAYER 2 (O)",
                      isActive: currentTurn == player2,
                      isYou: _currentPlayerId == player2,
                      color: Colors.amberAccent,
                    ),
                  ],
                ),
                SizedBox(height: size.height * 0.04),
                if (winner.isNotEmpty)
                  Text(
                    winner == "X" ? "Player 1 Wins!" : "Player 2 Wins!",
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w300,
                      color: Colors.lightGreen,
                    ),
                  ),
                if (isTie)
                  const Text(
                    "It's a Tie!",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w300,
                      color: Colors.tealAccent,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: GridView.builder(
                    itemCount: 9,
                    padding: const EdgeInsets.all(10),
                    shrinkWrap: true,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 1,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => isCurrentPlayer ? _makeMove(index) : null,
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(10),
                            border: isCurrentPlayer
                                ? Border.all(color: Colors.white30, width: 2)
                                : null,
                          ),
                          child: board[index].isEmpty
                              ? null
                              : Text(
                                  board[index],
                                  style: TextStyle(
                                    fontSize: 50,
                                    fontWeight: FontWeight.bold,
                                    color: board[index] == "X"
                                        ? Colors.blueAccent
                                        : Colors.amberAccent,
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
                ),
                if (showReset)
                  ElevatedButton(
                    onPressed: _resetGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Play Again"),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isYou;
  final Color color;

  const _PlayerCard({
    required this.label,
    required this.isActive,
    required this.isYou,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      transform: Matrix4.identity()..scale(isActive ? 1.1 : 1.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isActive ? color : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(
              Icons.person,
              color: color,
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isYou)
              const Text(
                "(You)",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

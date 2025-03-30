import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

class GameService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> createGame(String playerId) async {
    try {
      final gameCode = _generateGameCode();
      final gameRef = _firestore.collection('games').doc(gameCode);
      await gameRef.set({
        'player1': playerId,
        'player2': '',
        'currentTurn': playerId,
        'boardState': List.filled(9, ''),
        'status': 'waiting',
        'winner': '',
        'createdAt': FieldValue.serverTimestamp(), // Fixed the error
        'players': [playerId],
      }, SetOptions(merge: true));

      return gameCode;
    } catch (e) {
      Fluttertoast.showToast(msg: "Game creation failed: ${e.toString()}");
      rethrow;
    }
  }

  Future<bool> joinGame(String gameCode, String playerId) async {
    try {
      final docRef = _firestore.collection('games').doc(gameCode);

      return await _firestore.runTransaction<bool>((transaction) async {
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          throw Exception('Game does not exist');
        }

        final data = snapshot.data() as Map<String, dynamic>;

        // Prevent self-joining
        if (data['player1'] == playerId) {
          throw Exception('Cannot join your own game');
        }

        // Check if player2 slot is available
        if (data['player2'].toString().isNotEmpty) {
          return false;
        }

        // Update game state
        transaction.update(docRef, {
          'player2': playerId,
          'status': 'playing',
          'currentTurn': data['player1'],
        });

        return true;
      });
    } catch (e) {
      print('Join error: $e');
      return false;
    }
  }

  Stream<DocumentSnapshot> gameStream(String gameCode) {
    return _firestore.collection('games').doc(gameCode).snapshots();
  }

  Future<void> makeMove(String gameCode, int index, String symbol) async {
    final docRef = _firestore.collection('games').doc(gameCode);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      final board = List<String>.from(snapshot['boardState']);

      if (board[index].isEmpty) {
        board[index] = symbol;
        transaction.update(docRef, {
          'boardState': board,
          'currentTurn': snapshot['currentTurn'] == snapshot['player1']
              ? snapshot['player2']
              : snapshot['player1'],
        });
      }
    });
  }

  String _generateGameCode() {
    return DateTime.now().millisecondsSinceEpoch.toString().substring(7);
  }
}

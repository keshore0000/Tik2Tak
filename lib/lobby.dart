import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'game_service.dart';

class LobbyScreen extends StatelessWidget {
  final GameService _gameService = GameService();
  final TextEditingController _codeController = TextEditingController();

  Future<void> _createGame(BuildContext context, User user) async {
    try {
      final gameCode = await _gameService.createGame(user.uid);
      Navigator.pushNamed(context, '/game', arguments: gameCode);
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to create game: ${e.toString()}",
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _joinGame(BuildContext context, User user) async {
    if (_codeController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "Please enter a game code",
        backgroundColor: Colors.orange,
      );
      return;
    }

    try {
      final success = await _gameService.joinGame(_codeController.text, user.uid);
      if (success) {
        Navigator.pushNamed(context, '/game', arguments: _codeController.text);
      } else {
        Fluttertoast.showToast(
          msg: "Invalid game code or game full",
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to join game: ${e.toString()}",
        backgroundColor: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple, Colors.red],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => _createGame(context, user!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15),
                  ),
                  child: const Text(
                    'Create New Game',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'OR',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: _codeController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter Game Code',
                    hintStyle: const TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.black26,
                  ),
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _joinGame(context, user!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 15),
                  ),
                  child: const Text(
                    'Join Game',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import 'auth.dart';
import 'game.dart';
import 'lobby.dart';
import 'login.dart';
import 'reg.dart';

void main() async {
  //For sure use these 2 lines to integrate Firebase.
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  Fluttertoast.showToast(msg: "App initialized");

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  await FirebaseFirestore.instance.collection('games')
      .limit(1)
      .get(const GetOptions(source: Source.cache))
      .catchError((_) => FirebaseFirestore.instance.collection('games').limit(1).get());
  // This line is to wrap the whole app with Provider to handle user state.
  runApp(
    MultiProvider(
      providers: [
        StreamProvider<User?>.value(
          value: AuthService().authStateChanges,
          initialData: null,
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      //Re-Direction
      routes: {
        '/': (context) => const AuthWrapper(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegistrationScreen(),
        '/lobby': (context) => LobbyScreen(),
        '/game': (context) => const GameScreenWrapper(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    //we got the last user from the StreamUser
    final user = Provider.of<User?>(context);
    return user == null ? LoginScreen() : LobbyScreen();
  }
}

class GameScreenWrapper extends StatelessWidget {
  const GameScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final gameCode = ModalRoute.of(context)!.settings.arguments as String;
    return GameScreen(gameCode: gameCode);
  }
}

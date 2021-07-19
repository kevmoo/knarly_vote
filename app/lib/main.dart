import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'src/auth_model.dart';
import 'src/vote_widget.dart';

Future<void> main() async {
  //await Firebase.initializeApp();
  runApp(_KnarlyApp());
}

class _KnarlyApp extends StatelessWidget {
  static const _title = 'Knarly Vote';

  _KnarlyApp();

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: _title,
        theme: ThemeData(),
        home: Scaffold(
          appBar: AppBar(title: const Text(_title)),
          body: ChangeNotifierProvider(
            create: (_) => FirebaseAuthModel(),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Consumer<FirebaseAuthModel>(
                  builder: (context, authModel, __) {
                    final user = authModel.value;

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (user == null)
                                ElevatedButton(
                                  onPressed: _onSignIn,
                                  child: const Text(
                                      'Sign in with your Google account'),
                                ),
                              if (user != null) ...[
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(user.email ?? '?@?.com'),
                                ),
                                ElevatedButton(
                                  onPressed: _onSignOut,
                                  child: const Text(
                                    'Sign out',
                                  ),
                                ),
                              ]
                            ],
                          ),
                        ),
                        Expanded(
                          child: user == null ? Container() : VoteWidget(user),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

  Future<void> _onSignIn() async {
    try {
      final googleProvider = GoogleAuthProvider()..addScope('email');
      await FirebaseAuth.instance.signInWithPopup(googleProvider);
    } catch (error) {
      print(error);
    }
  }

  Future<void> _onSignOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (error) {
      print(error);
    }
  }
}

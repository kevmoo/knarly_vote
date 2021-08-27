import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:knarly_common/knarly_common.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/link.dart';

import 'src/auth_model.dart';
import 'src/temp.dart';
import 'src/vote_widget.dart';

Future<void> main() async {
  setUrlStrategy(PathUrlStrategy());
  runApp(_KnarlyApp());
}

const _sourceUrl = 'github.com/kevmoo/knarly_vote';
final _sourceUri = Uri.parse('https://$_sourceUrl');

class _KnarlyApp extends StatelessWidget {
  static const _title = 'Knarly Vote';

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: _title,
        home: Scaffold(
          appBar: AppBar(
            title: const Text(_title),
          ),
          bottomNavigationBar: Link(
            uri: _sourceUri,
            target: LinkTarget.blank,
            builder: (context, followLink) => ElevatedButton(
              onPressed: followLink,
              child: const Text('Source: $_sourceUrl'),
            ),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ChangeNotifierProvider(
                create: (_) => FirebaseAuthModel(),
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
                                    'Sign in with your Google account',
                                  ),
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
                        Expanded(child: _withUser(user)),
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

Widget _withUser(User? user) => user == null
    ? const Center(child: Text('Must sign in...'))
    : FutureBuilder<Election>(
        future: downloadFirstElection(user),
        builder: (buildContext, snapshot) {
          if (snapshot.hasError) {
            // TODO: Probably could do something a bit better here...
            return Center(
              child: Text(
                snapshot.error.toString(),
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (snapshot.hasData) {
            return VoteWidget(user, snapshot.requireData);
          }

          return const Center(child: Text('Downloading election...'));
        },
      );

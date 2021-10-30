import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../shared.dart';

class LoginWidget extends StatelessWidget {
  final String? from;
  const LoginWidget({this.from, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              onPressed: () async {
                await _onSignIn();
                if (from != null) context.go(from!);
              },
              child: const Text('Sign in with your Google account'),
            ),
          ),
          const SelectableText.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: siteTitle,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: _intro),
                TextSpan(text: '\n\n'),
                TextSpan(
                  text: _cya,
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          )
        ],
      );

  Future<void> _onSignIn() async {
    try {
      final googleProvider = GoogleAuthProvider()..addScope('email');
      await FirebaseAuth.instance.signInWithPopup(googleProvider);
      FirebaseAnalytics().logLogin(loginMethod: 'google').ignore();
    } catch (error) {
      print('Error caught during Firebase sign-in: $error');
    }
  }
}

const _intro =
    ' allows you to try out ranked voting in real time with many people. '
    "It's still very much a work in progress. "
    '\n\n'
    'Checkout out the repository linked below 👇 if you want to ask questions, '
    'file issues, etc.';

const _cya =
    'At the moment, I do collect your Google account email as part of login. '
    'I will never give/sell it to anyone unless required to by law. '
    'At some point I may email folks who have used this site to announce new '
    'features, etc, but I will make it trivial to remove yourself if you like.';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignedInUserWidget extends StatelessWidget {
  final User user;
  final Widget child;
  const SignedInUserWidget({required this.user, required this.child, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(user.email ?? '?@?.com'),
                ),
                ElevatedButton(
                  onPressed: _onSignOut,
                  child: const Text('Sign out'),
                ),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      );

  Future<void> _onSignOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (error) {
      print(error);
    }
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:routemaster/routemaster.dart';
import 'package:url_launcher/link.dart';

import 'src/auth_widget.dart';
import 'src/election_list_widget.dart';
import 'src/election_show_widget.dart';

Future<void> main() async {
  runApp(_KnarlyApp());
}

const _sourceUrl = 'github.com/kevmoo/knarly_vote';
final _sourceUri = Uri.parse('https://$_sourceUrl');

class _KnarlyApp extends StatelessWidget {
  _KnarlyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => AuthWidget(
        (context, user) => MaterialApp.router(
          routerDelegate: RoutemasterDelegate(
            routesBuilder: (context) {
              if (user == null) {
                return _loggedOutRouteMap;
              }

              return _loggedInRouteMap(user);
            },
          ),
          routeInformationParser: const RoutemasterParser(),
        ),
      );

  late final _loggedOutRouteMap = RouteMap(
    onUnknownRoute: (route) => const Redirect('/'),
    routes: {
      '/': (_) => _scaffold(
            ElevatedButton(
              onPressed: _onSignIn,
              child: const Text('Sign in with your Google account'),
            ),
          ),
    },
  );

  RouteMap _loggedInRouteMap(User user) => RouteMap(
        onUnknownRoute: (route) {
          print('logged in route unknown! $route');
          return const Redirect('/elections');
        },
        routes: {
          '/elections': (_) =>
              _scaffoldSignedIn(user, ElectionListWidget(user)),
          '/elections/:id': (route) => _scaffoldSignedIn(
                user,
                ElectionShowWidget(user, route.pathParameters['id']!),
              ),
        },
      );

  RouteSettings _scaffoldSignedIn(User user, Widget child) => _scaffold(
        Column(
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

RouteSettings _scaffold(Widget child) => MaterialPage(
      child: Scaffold(
        appBar: AppBar(title: const Text('Knarlry vote')),
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
            child: Container(
              child: child,
            ),
          ),
        ),
      ),
    );

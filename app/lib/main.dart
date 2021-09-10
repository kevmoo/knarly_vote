import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';
import 'package:routemaster/routemaster.dart';
import 'package:url_launcher/link.dart';

import 'src/shared.dart';
import 'src/widgets/auth_widget.dart';
import 'src/widgets/election_list_widget.dart';
import 'src/widgets/election_show_widget.dart';
import 'src/widgets/root_widget.dart';
import 'src/widgets/signed_in_user_widget.dart';

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
          title: siteTitle,
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
            key: _rootKey,
            child: const RootWidget(),
          )
    },
  );

  RouteMap _loggedInRouteMap(User user) => RouteMap(
        onUnknownRoute: (route) {
          print('logged in route unknown! $route');
          return const Redirect('/elections');
        },
        routes: {
          '/elections': (_) => _scaffoldSignedIn(
                key: _electionListKey,
                user: user,
                child: ElectionListWidget(user),
              ),
          '/elections/:id': (route) => _scaffoldSignedIn(
                key: _electionShowKey,
                user: user,
                child: ElectionShowWidget(user, route.pathParameters['id']!),
              ),
        },
      );

  MaterialPage _scaffoldSignedIn({
    required User user,
    required Widget child,
    required LocalKey key,
  }) =>
      _scaffold(
        child: SignedInUserWidget(
          user: user,
          child: child,
        ),
        key: key,
      );

  static final _rootKey = UniqueKey();
  static final _electionListKey = UniqueKey();
  static final _electionShowKey = UniqueKey();
}

MaterialPage _scaffold({
  required LocalKey key,
  required Widget child,
}) =>
    MaterialPage(
      key: key,
      maintainState: false,
      child: _ScaffoldWidget(child: child),
    );

class _ScaffoldWidget extends StatelessWidget {
  final Widget child;
  const _ScaffoldWidget({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text(siteTitle)),
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
      );
}

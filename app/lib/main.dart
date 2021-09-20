import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:routemaster/routemaster.dart';
import 'package:url_launcher/link.dart';

import 'src/auth_model.dart';
import 'src/observer.dart';
import 'src/shared.dart';
import 'src/theme_data.dart';
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
        child: Consumer<FirebaseAuthModel>(
          builder: (context, authModel, _) => MaterialApp.router(
            title: siteTitle,
            theme: themeData,
            routerDelegate: RoutemasterDelegate(
              routesBuilder: (context) {
                final user = authModel.user;
                if (user == null) {
                  return _loggedOutRouteMap;
                }

                return _loggedInRouteMap(user);
              },
              observers: [observer],
            ),
            routeInformationParser: const RoutemasterParser(),
          ),
        ),
      );

  late final _loggedOutRouteMap = RouteMap(
    onUnknownRoute: (route) => const Redirect('/'),
    routes: {
      '/': (_) => _scaffold(
            name: 'Sign-in',
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
                name: 'List Elections',
                key: ObjectKey('${user.uid}-election-list'),
                user: user,
                child: const ElectionListWidget(),
              ),
          '/elections/:id': (route) {
            final electionId = route.pathParameters['id'];
            return _scaffoldSignedIn(
              name: 'Show Election - $electionId',
              key: ObjectKey('${user.uid}-election-show'),
              user: user,
              child: ElectionShowWidget(electionId!),
            );
          },
        },
      );

  MaterialPage _scaffoldSignedIn({
    required String name,
    required User user,
    required Widget child,
    required LocalKey key,
  }) =>
      _scaffold(
        name: name,
        key: key,
        child: SignedInUserWidget(
          user: user,
          child: child,
        ),
      );

  static final _rootKey = UniqueKey();
}

MaterialPage _scaffold({
  required String name,
  required LocalKey key,
  required Widget child,
}) =>
    MaterialPage(
      name: name,
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
        body: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: child,
            ),
          ),
        ),
      );
}

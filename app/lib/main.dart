import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/link.dart';

import 'src/auth_model.dart';
import 'src/routing.dart';
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
          builder: (context, authModel, _) {
            final router = _router(authModel.user);
            return MaterialApp.router(
              title: siteTitle,
              theme: themeData,
              routerDelegate: router.routerDelegate,
              routeInformationParser: router.routeInformationParser,
            );
          },
        ),
      );

  GoRouter _router(User? user) {
    if (user == null) {
      return _loggedOutRouter;
    }
    return _loggedInRouteMap(user);
  }

  late final _loggedOutRouter = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => _scaffold(
          name: 'Sign-in',
          key: _rootKey,
          child: const RootWidget(),
        ),
      ),
    ],
    redirect: (state) {
      if (state.location == '/') return null;
      return '/';
    },
    errorPageBuilder: _errorPageBuilder,
    observers: _observers,
  );

  GoRouter _loggedInRouteMap(User user) => GoRouter(
        routes: [
          GoRoute(path: '/', redirect: (_) => '/elections'),
          GoRoute(
            path: '/elections',
            pageBuilder: (a, b) => _scaffoldSignedIn(
              name: 'List Elections',
              key: ObjectKey('${user.uid}-election-list'),
              user: user,
              child: const ElectionListWidget(),
            ),
            routes: [
              GoRoute(
                name: ContextExtensions.viewElectionRoutName,
                path: ':${ContextExtensions.viewElectionIdParamName}',
                pageBuilder: (context, state) {
                  final electionId =
                      state.params[ContextExtensions.viewElectionIdParamName]!;
                  return _scaffoldSignedIn(
                    name: 'Show Election - $electionId',
                    key: ObjectKey('${user.uid}-election-show'),
                    user: user,
                    child: ElectionShowWidget(electionId),
                  );
                },
              )
            ],
          ),
        ],
        errorPageBuilder: _errorPageBuilder,
        observers: _observers,
      );

  Page<dynamic> _errorPageBuilder(
    BuildContext context,
    GoRouterState state,
  ) =>
      MaterialPage<void>(key: state.pageKey, child: const Text('Boo...'));

  final _observers = [
    FirebaseAnalyticsObserver(analytics: FirebaseAnalytics())
  ];

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

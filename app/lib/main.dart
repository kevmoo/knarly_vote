import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/link.dart';

import 'src/auth_model.dart';
import 'src/routing.dart';
import 'src/shared.dart';
import 'src/theme_data.dart';
import 'src/widgets/election_list_widget.dart';
import 'src/widgets/election_show_widget.dart';
import 'src/widgets/login_widget.dart';
import 'src/widgets/network_async_widget.dart';

Future<void> main() async {
  runApp(_KnarlyApp());
}

const _sourceUrl = 'github.com/kevmoo/knarly_vote';
final _sourceUri = Uri.parse('https://$_sourceUrl');

class _KnarlyApp extends StatelessWidget {
  _KnarlyApp({Key? key}) : super(key: key);
  final _auth = FirebaseAuthModel();

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.ltr,
        child: NetworkAsyncWidget<void>(
          valueFactory: () => _auth.initializationComplete,
          waitingText: 'Loading...',
          builder: (context, data) => MaterialApp.router(
            title: siteTitle,
            theme: themeData,
            routerDelegate: _router.routerDelegate,
            routeInformationParser: _router.routeInformationParser,
          ),
        ),
      );

  late final _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => _scaffold(
          name: 'Sign-in',
          key: state.pageKey,
          child: LoginWidget(from: state.queryParams['from']),
        ),
      ),
      GoRoute(
        path: '/elections',
        pageBuilder: (a, b) => _scaffold(
          name: 'List Elections',
          key: b.pageKey,
          child: const ElectionListWidget(),
        ),
        routes: [
          GoRoute(
            name: ContextExtensions.viewElectionRoutName,
            path: ':${ContextExtensions.viewElectionIdParamName}',
            pageBuilder: (context, state) {
              final electionId =
                  state.params[ContextExtensions.viewElectionIdParamName]!;
              return _scaffold(
                name: 'Show Election - $electionId',
                key: state.pageKey,
                child: ElectionShowWidget(electionId),
              );
            },
          )
        ],
      ),
    ],
    redirect: (state) {
      final user = _auth.user;

      if (user == null) {
        if (state.subloc == '/') return null;
        return '/?from=${state.subloc}';
      }

      if (state.subloc == '/') return '/elections';
      return null;
    },
    errorPageBuilder: _errorPageBuilder,
    observers: _observers,
    refreshListenable: _auth,
    navigatorBuilder: (ctx, child) {
      final user = _auth.user;
      return ChangeNotifierProvider.value(
        value: _auth,
        child: user == null
            ? child
            : Stack(
                children: [
                  child!,
                  Positioned(
                    // Need to "sync" with bottom bar size
                    bottom: 40,
                    right: 10,
                    child: ElevatedButton(
                      onPressed: _onSignOut,
                      child: const Icon(Icons.logout),
                    ),
                  )
                ],
              ),
      );
    },
  );

  Page<dynamic> _errorPageBuilder(
    BuildContext context,
    GoRouterState state,
  ) =>
      MaterialPage<void>(
        key: state.pageKey,
        child: Text('Boo...\n${state.error}'),
      );

  final _observers = [
    FirebaseAnalyticsObserver(analytics: FirebaseAnalytics())
  ];

  Future<void> _onSignOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (error) {
      print('Caught an error during Firebase sign-out: $error');
    }
  }
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
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: child,
              ),
            ),
          ),
        ),
      );
}

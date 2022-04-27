import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'src/auth_model.dart';
import 'src/routing.dart';
import 'src/shared.dart';
import 'src/theme_data.dart';
import 'src/widgets/network_async_widget.dart';

Future<void> main() async {
  runApp(_KnarlyApp());
}

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
    routes: $appRoutes,
    redirect: (state) {
      final user = _auth.user;

      if (user == null) {
        if (state.subloc == '/') return null;
        return LoginRoute(from: state.subloc).location;
      }

      if (state.subloc == '/') return const ElectionsRoute().location;
      return null;
    },
    errorPageBuilder: _errorPageBuilder,
    observers: _observers,
    refreshListenable: _auth,
    navigatorBuilder: (ctx, state, child) {
      final user = _auth.user;
      return ChangeNotifierProvider.value(
        value: _auth,
        child: user == null
            ? child
            : Stack(
                children: [
                  child,
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

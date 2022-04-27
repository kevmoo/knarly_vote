// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routing.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<GoRoute> get $appRoutes => [
      $loginRoute,
    ];

GoRoute get $loginRoute => GoRouteData.$route(
      path: '/',
      factory: $LoginRouteExtension._fromState,
      routes: [
        GoRouteData.$route(
          path: 'elections',
          factory: $ElectionsRouteExtension._fromState,
          routes: [
            GoRouteData.$route(
              path: ':id',
              factory: $ElectionViewRouteExtension._fromState,
            ),
          ],
        ),
      ],
    );

extension $LoginRouteExtension on LoginRoute {
  static LoginRoute _fromState(GoRouterState state) => LoginRoute(
        from: state.queryParams['from'],
      );

  String get location => GoRouteData.$location(
        '/',
        queryParams: {
          if (from != null) 'from': from!,
        },
      );

  void go(BuildContext buildContext) => buildContext.go(location, extra: this);
}

extension $ElectionsRouteExtension on ElectionsRoute {
  static ElectionsRoute _fromState(GoRouterState state) =>
      const ElectionsRoute();

  String get location => GoRouteData.$location(
        '/elections',
      );

  void go(BuildContext buildContext) => buildContext.go(location, extra: this);
}

extension $ElectionViewRouteExtension on ElectionViewRoute {
  static ElectionViewRoute _fromState(GoRouterState state) => ElectionViewRoute(
        state.params['id']!,
      );

  String get location => GoRouteData.$location(
        '/elections/${Uri.encodeComponent(id)}',
      );

  void go(BuildContext buildContext) => buildContext.go(location, extra: this);
}

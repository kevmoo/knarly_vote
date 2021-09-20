import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:flutter/material.dart';
import 'package:routemaster/routemaster.dart';

final _analytics = FirebaseAnalytics();
final observer = _RouteMasterFirebaseObserver(analytics: _analytics);

class _RouteMasterFirebaseObserver extends FirebaseAnalyticsObserver
    implements RoutemasterObserver {
  _RouteMasterFirebaseObserver({required FirebaseAnalytics analytics})
      : super(analytics: analytics);

  @override
  void didChangeRoute(RouteData routeData, Page page) {
    final screenName = page.name;
    if (screenName != null) {
      analytics.setCurrentScreen(screenName: screenName).catchError(
        (Object error) {
          debugPrint('$FirebaseAnalyticsObserver: $error');
        },
      );
    }
  }
}

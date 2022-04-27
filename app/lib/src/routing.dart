import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/link.dart';

import 'shared.dart';
import 'widgets/election_list_widget.dart';
import 'widgets/election_show_widget.dart';
import 'widgets/login_widget.dart';

part 'routing.g.dart';

const _sourceUrl = 'github.com/kevmoo/knarly_vote';
final _sourceUri = Uri.parse('https://$_sourceUrl');

@TypedGoRoute<LoginRoute>(
  path: '/',
  routes: [
    TypedGoRoute<ElectionsRoute>(
      path: 'elections',
      routes: [
        TypedGoRoute<ElectionViewRoute>(path: ':id'),
      ],
    ),
  ],
)
class LoginRoute extends GoRouteData {
  const LoginRoute({this.from});

  final String? from;

  @override
  Page<void> buildPage(BuildContext context) => _scaffold(
        key: const ValueKey('/'),
        child: LoginWidget(from: from),
      );
}

class ElectionsRoute extends GoRouteData {
  const ElectionsRoute();

  @override
  Page<void> buildPage(BuildContext context) => _scaffold(
        key: const ValueKey('/elections'),
        child: const ElectionListWidget(),
      );
}

class ElectionViewRoute extends GoRouteData {
  const ElectionViewRoute(this.id);

  final String id;

  @override
  Page<void> buildPage(BuildContext context) => _scaffold(
        key: const ValueKey('/elections/:id'),
        child: ElectionShowWidget(id),
      );
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

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

import '../auth_model.dart';
import '../provider_consumer_combo.dart';

class AuthWidget extends StatelessWidget {
  final Widget Function(BuildContext context, User? user) _builder;

  AuthWidget(this._builder);

  @override
  Widget build(BuildContext context) =>
      createProviderConsumer<FirebaseAuthModel>(
        create: (_) => FirebaseAuthModel(),
        builder: (context, authModel, __) => FutureBuilder(
          future: authModel.initializationComplete,
          builder: (context, snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.done:
                return _builder(context, authModel.value);
              default:
                return const Text(
                  'Loading...',
                  textDirection: TextDirection.ltr,
                );
            }
          },
        ),
      );
}

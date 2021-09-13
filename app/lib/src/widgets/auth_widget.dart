import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../auth_model.dart';
import 'network_async_widget.dart';

class AuthWidget extends StatelessWidget {
  final _auth = FirebaseAuthModel();
  final Widget child;

  AuthWidget({required this.child});

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.ltr,
        child: NetworkAsyncWidget<void>(
          valueFactory: () => _auth.initializationComplete,
          waitingText: 'Loading...',
          builder: (context, data) =>
              ChangeNotifierProvider.value(value: _auth, child: child),
        ),
      );
}

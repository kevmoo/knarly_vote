import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebaseAuthModel extends ChangeNotifier
    implements ValueListenable<User?> {
  StreamSubscription<User?>? _subscription;

  @override
  User? get value => FirebaseAuth.instance.currentUser;

  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
    if (_subscription == null && hasListeners) {
      _subscription = FirebaseAuth.instance.userChanges().listen((_) {
        assert(_subscription != null);
        notifyListeners();
      });
    }
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    if (_subscription != null && !hasListeners) {
      _subscription?.cancel();
      _subscription = null;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

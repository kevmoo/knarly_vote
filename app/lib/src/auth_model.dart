import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebaseAuthModel extends ChangeNotifier
    implements ValueListenable<User?> {
  final _initializeCompleter = Completer<void>.sync();

  StreamSubscription<User?>? _subscription;

  Future<void> get initializationComplete => _initializeCompleter.future;

  @override
  User? get value => FirebaseAuth.instance.currentUser;

  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
    if (_subscription == null && hasListeners) {
      _subscription = FirebaseAuth.instance.userChanges().listen((_) {
        assert(_subscription != null);
        if (!_initializeCompleter.isCompleted) {
          _initializeCompleter.complete();
        }
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

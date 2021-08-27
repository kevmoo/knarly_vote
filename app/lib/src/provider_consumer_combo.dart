import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

Widget createProviderConsumer<T extends ChangeNotifier>({
  required Create<T> create,
  required Widget Function(
    BuildContext context,
    T value,
    Widget? child,
  )
      builder,
}) =>
    ChangeNotifierProvider<T>(
      create: create,
      child: Consumer<T>(builder: builder),
    );

Widget valueProviderConsumer<T extends ChangeNotifier>({
  required T value,
  required Widget Function(
    BuildContext context,
    T value,
    Widget? child,
  )
      builder,
}) =>
    ChangeNotifierProvider<T>.value(
      value: value,
      child: Consumer<T>(builder: builder),
    );

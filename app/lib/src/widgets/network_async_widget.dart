import 'dart:async';

import 'package:flutter/material.dart';

import '../network_exception.dart';

class NetworkAsyncWidget<T> extends StatefulWidget {
  final Future<T> Function() valueFactory;
  final String waitingText;
  final Widget Function(BuildContext context, T data) builder;

  const NetworkAsyncWidget({
    Key? key,
    required this.valueFactory,
    required this.waitingText,
    required this.builder,
  }) : super(key: key);

  @override
  _NetworkAsyncWidgetState<T> createState() => _NetworkAsyncWidgetState<T>();
}

class _NetworkAsyncWidgetState<T> extends State<NetworkAsyncWidget<T>> {
  Future<T>? _futureCache;

  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            final error = snapshot.error;

            String text;
            if (error is NetworkException) {
              text = '''
${error.message}

Status code: ${error.statusCode}
Url: ${error.uri}''';

              if (error.cloudTraceContext != null) {
                text += '\nCloud trace context: ${error.cloudTraceContext}';
              }
            } else {
              text = error.toString();
            }

            return SelectableText(
              text,
              textScaleFactor: 1.4,
              style: TextStyle(color: Theme.of(context).errorColor),
            );
          }

          if (snapshot.hasData) {
            return widget.builder(context, snapshot.requireData);
          }

          return Center(child: Text(widget.waitingText));
        },
      );

  Future<T> get _future => _futureCache ??= widget.valueFactory();
}

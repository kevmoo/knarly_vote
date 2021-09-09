import 'package:flutter/material.dart';

class NetworkAsyncWidget<T> extends StatelessWidget {
  final Future<T> future;
  final String waitingText;
  final Widget Function(BuildContext context, T data) builder;

  const NetworkAsyncWidget({
    Key? key,
    required this.future,
    required this.waitingText,
    required this.builder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            // TODO: Probably could do something a bit better here...
            return Center(
              child: Text(
                snapshot.error.toString(),
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (snapshot.hasData) {
            return builder(context, snapshot.requireData);
          }

          return Center(child: Text(waitingText));
        },
      );
}

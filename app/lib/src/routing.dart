import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

extension ContextExtensions on BuildContext {
  static const viewElectionRoutName = 'view_election';
  static const viewElectionIdParamName = 'id';

  void pushViewElection(String electionId) => pushNamed(
        viewElectionRoutName,
        params: {viewElectionIdParamName: electionId},
      );
}

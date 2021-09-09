// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: require_trailing_commas

part of 'service.dart';

// **************************************************************************
// ShelfRouterGenerator
// **************************************************************************

Router _$VoteServiceRouter(VoteService service) {
  final router = Router();
  router.add('GET', r'/api/config.js', service.getConfig);
  router.add('GET', r'/api/elections/', service.listElections);
  router.add('GET', r'/api/elections/<electionId>/', service.getElection);
  router.add('GET', r'/api/ballots/<electionId>/', service.ballot);
  router.add('PUT', r'/api/ballots/<electionId>/', service.updateBallot);
  router.add('POST', r'/api/elections/<electionId>/update',
      service.updateElectionResult);
  return router;
}

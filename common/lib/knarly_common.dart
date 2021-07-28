export 'src/election.dart';

const rootCollectionName = 'elections';

String electionDocumentPath(String electionId) =>
    '$rootCollectionName/$electionId';

String electionResultPath(String electionId) =>
    '${electionDocumentPath(electionId)}/results/condorcet';

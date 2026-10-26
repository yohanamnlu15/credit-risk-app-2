class PredictionResult {
  final String status;
  final double confidence;
  final DateTime analyzedAt;
  final String debiturName;
  final Map<String, String> summaryFactors;
  final Map<String, double> probabilities;

  const PredictionResult({
    required this.status,
    required this.confidence,
    required this.analyzedAt,
    required this.debiturName,
    required this.summaryFactors,
    required this.probabilities,
  });

  bool get isLancar => status == 'Lancar';
}
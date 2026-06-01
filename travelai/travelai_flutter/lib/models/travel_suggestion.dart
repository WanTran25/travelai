class TravelSuggestion {
  final int placeId;
  final String reason;

  TravelSuggestion({required this.placeId, required this.reason});

  factory TravelSuggestion.fromJson(Map<String, dynamic> json) =>
      TravelSuggestion(
        placeId: json['place_id'] as int,
        reason: json['reason'] as String,
      );
}

class Report {
  final String id;
  final double latitude;
  final double longitude;
  final String imageUrl;
  final String wasteCategory;
  final String comment;
  final String createAt;

  Report({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    required this.wasteCategory,
    required this.comment,
    required this.createAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'latitude': latitude,
    'longitude': longitude,
    'imageUrl': imageUrl,
    'wasteCategory': wasteCategory,
    'comment': comment,
    'createAt': createAt,
  };
}

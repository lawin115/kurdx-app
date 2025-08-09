class AuctionImage {
  final int id;
  final String url;

  AuctionImage({required this.id, required this.url});

factory AuctionImage.fromJson(Map<String, dynamic> json) {
  const String baseUrl = "https://ubuntu.tail73d562.ts.net"; // Your Laravel server base URL
  String imageUrl = json['path'].startsWith('https') 
      ? json['path'] 
      : '$baseUrl/storage/${json['path']}';

  // Log the image URL to verify it's correct
  print("Generated Image URL: $imageUrl");

  return AuctionImage(
    id: json['id'],
    url: imageUrl,
  );
}


}

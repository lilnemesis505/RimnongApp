class Product {
  final String proId;
  final String proName;
  final double price;
  final String? imageUrl; // ถ้ามีรูปภาพ

  Product({
    required this.proId,
    required this.proName,
    required this.price,
    this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      proId: json['pro_id'],
      proName: json['pro_name'],
      price: double.parse(json['price'].toString()),
      imageUrl: json['image_url'], // ถ้ามี field นี้จาก API
    );
  }
}

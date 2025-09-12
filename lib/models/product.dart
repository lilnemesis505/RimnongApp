// lib/models/product.dart

class Product {
  final int proId; // ✅ แก้ไขจาก String เป็น int
  final String proName;
  final double price;
  final int typeId;
  final String? imageUrl;
  final String? imageId;

  Product({
    required this.proId,
    required this.proName,
    required this.price,
    required this.typeId,
    this.imageUrl,
    this.imageId,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      // ✅ แปลงค่า ID ต่างๆ ให้เป็น int
      proId: int.parse(json['pro_id'].toString()),
      typeId: int.parse(json['type_id'].toString()),

      proName: json['pro_name'],

      // ✅ แปลงค่า price ให้เป็น double
      price: double.parse(json['price'].toString()),

      imageUrl: json['image'],
      imageId: json['image_id'],
    );
  }
}
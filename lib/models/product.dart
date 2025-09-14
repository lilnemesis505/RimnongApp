class Product {
  final int proId;
  final String proName;
  final double price;
  final int typeId;
  final String? imageUrl;
  final String? imageId;
  // --- เพิ่ม field ใหม่ ---
  final double? specialPrice;
  final String? promoName;

  Product({
    required this.proId,
    required this.proName,
    required this.price,
    required this.typeId,
    this.imageUrl,
    this.imageId,
    // --- เพิ่ม parameter ---
    this.specialPrice,
    this.promoName,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      proId: int.parse(json['pro_id'].toString()),
      typeId: int.parse(json['type_id'].toString()),
      proName: json['pro_name'],
      price: double.parse(json['price'].toString()),
      imageUrl: json['image'],
      imageId: json['image_id'],
      // --- รับค่า field ใหม่จาก JSON ---
      specialPrice: json['special_price'] != null
          ? double.parse(json['special_price'].toString())
          : null,
      promoName: json['promo_name'],
    );
  }
}

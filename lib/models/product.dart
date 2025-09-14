class Product {
  final int proId;
  final String proName;
  final double price;
  final int typeId;
  final String? imageUrl;
  final String? imageId;
  final double? specialPrice;
  final String? promoName;
  // --- เพิ่ม Field ใหม่ ---
  final int? promoId;
  final double? promoDiscount;

  Product({
    required this.proId,
    required this.proName,
    required this.price,
    required this.typeId,
    this.imageUrl,
    this.imageId,
    this.specialPrice,
    this.promoName,
    // --- เพิ่ม Parameter ---
    this.promoId,
    this.promoDiscount,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      proId: int.parse(json['pro_id'].toString()),
      typeId: int.parse(json['type_id'].toString()),
      proName: json['pro_name'],
      price: double.parse(json['price'].toString()),
      imageUrl: json['image'],
      imageId: json['image_id'],
      specialPrice: json['special_price'] != null
          ? double.parse(json['special_price'].toString())
          : null,
      promoName: json['promo_name'],
      // --- รับค่า Field ใหม่จาก JSON ---
      promoId: json['promo_id'] != null 
          ? int.parse(json['promo_id'].toString()) 
          : null,
      promoDiscount: json['promo_discount'] != null
          ? double.parse(json['promo_discount'].toString())
          : null,
    );
  }
}

// models/order_detail.dart

class OrderDetail {
  final int proId;
  final String proName;
  final int amount;
  final double priceList;
  final double payTotal;

  OrderDetail({
    required this.proId,
    required this.proName,
    required this.amount,
    required this.priceList,
    required this.payTotal,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    final productData = json['product'];

    return OrderDetail(
      proId: int.parse(json['pro_id'].toString()),
      proName: productData != null ? productData['pro_name'] : 'ไม่พบชื่อสินค้า',
      amount: int.parse(json['amount'].toString()),
      priceList: double.parse(json['price_list'].toString()),
      payTotal: double.parse(json['pay_total'].toString()),
    );
  }
}
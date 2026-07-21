class CartItem {
  const CartItem({
    required this.dbType,
    required this.action,
    required this.serviceType,
    required this.carImage,
    required this.carMakeModel,
    required this.carNo,
    required this.packAmount,
    required this.carId,
    required this.paidMonths,
    required this.fineAmount,
    required this.subTotal,
    required this.gstPercent,
    required this.gstAmount,
    required this.totalAmount,
    this.platformFeeAmt = '',
    this.serviceFeeAmt = '',
    required this.scheduleDate,
    required this.scheduleTime,
    required this.carName,
    required this.carCategory,
    required this.header,
    this.sourceOrderId = '',
  });

  final String dbType;
  final String action;
  final String serviceType;
  final String carImage;
  final String carMakeModel;
  final String carNo;
  final String packAmount;
  final String carId;
  final String paidMonths;
  final String fineAmount;
  final String subTotal;
  final String gstPercent;
  final String gstAmount;
  final String totalAmount;
  final String platformFeeAmt;
  final String serviceFeeAmt;
  final String scheduleDate;
  final String scheduleTime;
  final String carName;
  final String carCategory;
  final String header;
  final String sourceOrderId;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'dbType': dbType,
        'action': action,
        'serviceType': serviceType,
        'carImage': carImage,
        'carMakeModel': carMakeModel,
        'carNo': carNo,
        'packAmount': packAmount,
        'carId': carId,
        'paidMonths': paidMonths,
        'fineAmount': fineAmount,
        'subTotal': subTotal,
        'gstPercent': gstPercent,
        'gstAmount': gstAmount,
        'totalAmount': totalAmount,
        'platformFeeAmt': platformFeeAmt,
        'serviceFeeAmt': serviceFeeAmt,
        'scheduleDate': scheduleDate,
        'scheduleTime': scheduleTime,
        'carName': carName,
        'carCategory': carCategory,
        'header': header,
        'sourceOrderId': sourceOrderId,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      dbType: (json['dbType'] ?? '').toString(),
      action: (json['action'] ?? '').toString(),
      serviceType: (json['serviceType'] ?? '').toString(),
      carImage: (json['carImage'] ?? '').toString(),
      carMakeModel: (json['carMakeModel'] ?? '').toString(),
      carNo: (json['carNo'] ?? '').toString(),
      packAmount: (json['packAmount'] ?? '').toString(),
      carId: (json['carId'] ?? '').toString(),
      paidMonths: (json['paidMonths'] ?? '1').toString(),
      fineAmount: (json['fineAmount'] ?? '0').toString(),
      subTotal: (json['subTotal'] ?? '').toString(),
      gstPercent: (json['gstPercent'] ?? '0').toString(),
      gstAmount: (json['gstAmount'] ?? '0').toString(),
      totalAmount: (json['totalAmount'] ?? '').toString(),
      platformFeeAmt: (json['platformFeeAmt'] ?? '').toString(),
      serviceFeeAmt: (json['serviceFeeAmt'] ?? '').toString(),
      scheduleDate: (json['scheduleDate'] ?? '').toString(),
      scheduleTime: (json['scheduleTime'] ?? 'Anytime').toString(),
      carName: (json['carName'] ?? '').toString(),
      carCategory: (json['carCategory'] ?? '').toString(),
      header: (json['header'] ?? '').toString(),
      sourceOrderId: (json['sourceOrderId'] ?? '').toString(),
    );
  }
}

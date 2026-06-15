class InternalWashForm {
  const InternalWashForm({
    required this.id,
    required this.scheduleDate1,
    required this.scheduleTime1,
    required this.scheduleDate2,
    required this.scheduleTime2,
    required this.comment1,
    required this.comment2,
    required this.date1Editable,
    required this.date2Editable,
  });

  final String id;
  final String scheduleDate1;
  final String scheduleTime1;
  final String scheduleDate2;
  final String scheduleTime2;
  final String comment1;
  final String comment2;
  final bool date1Editable;
  final bool date2Editable;

  factory InternalWashForm.fromJson(Map<String, dynamic> json) {
    return InternalWashForm(
      id: (json['id'] ?? '').toString(),
      scheduleDate1: (json['schedule_date1'] ?? '').toString(),
      scheduleTime1: (json['schedule_time1'] ?? '').toString(),
      scheduleDate2: (json['schedule_date2'] ?? '').toString(),
      scheduleTime2: (json['schedule_time2'] ?? '').toString(),
      comment1: (json['comment_box1'] ?? '').toString(),
      comment2: (json['comment_box2'] ?? '').toString(),
      date1Editable: (json['date1_edit'] ?? '1').toString() == '1',
      date2Editable: (json['date2_edit'] ?? '1').toString() == '1',
    );
  }
}

// DataRecord model
class DataRecord {
  final int id;
  final String timestamp;
  final List<double> dataStream1;
  final List<double> dataStream2;

  DataRecord({
    required this.id,
    required this.timestamp,
    required this.dataStream1,
    required this.dataStream2,
  });
}

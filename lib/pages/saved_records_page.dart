import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:force_platform/controllers/data_repository.dart';
//import 'package:force_platform/models/data_record.dart'; // DataRecord 모델 경로에 맞게 수정
//import 'package:force_platform/pages/data_record_detail_page.dart';
import 'package:intl/intl.dart'; // 날짜 포맷팅을 위해 필요

class SavedRecordsPage extends StatelessWidget {
  const SavedRecordsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final DataRepository dataRepository = Get.find<DataRepository>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Saved Records'),
      ),
      body: FutureBuilder<List<DataRecord>>(
        future: dataRepository.fetchDataRecords(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // 데이터 로딩 중
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // 에러 발생
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            // 데이터 없음
            return Center(child: Text('No records found.'));
          } else {
            // 데이터가 존재할 경우 리스트 표시
            final records = snapshot.data!;
            return ListView.separated(
              padding: EdgeInsets.all(16.0),
              itemCount: records.length,
              separatorBuilder: (context, index) => SizedBox(height: 12),
              itemBuilder: (context, index) {
                final record = records[index];
                // timestamp를 읽기 쉬운 형식으로 변환
                final formattedTimestamp = DateFormat('yyyy-MM-dd - kk:mm:ss')
                    .format(DateTime.parse(record.timestamp));

                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: () {
                      Get.toNamed("/record_page",
                          arguments: {"record": record});
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.history,
                            color: Colors.blueAccent,
                            size: 40,
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  formattedTimestamp,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Data Stream 1: ${record.dataStream1.length} entries',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                Text(
                                  'Data Stream 2: ${record.dataStream2.length} entries',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.grey,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}

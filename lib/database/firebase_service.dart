
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final CollectionReference walksCol =
  FirebaseFirestore.instance.collection('walks');
  final CollectionReference recordsCol =
  FirebaseFirestore.instance.collection('records');

  Future<String> createWalk(Map<String, dynamic> walkData) async {
    final docRef = await walksCol.add(walkData);
    return docRef.id;
  }


  Future<String> createRecord(Map<String, dynamic> recordData) async {

    final walkDocId = recordData['walkDocId']?.toString() ?? '';
    if (walkDocId.isNotEmpty) {

      final walkSnap = await walksCol.doc(walkDocId).get();
      if (walkSnap.exists) {
        final wData = walkSnap.data() as Map<String, dynamic>;
        final wType = wData['walkType']?.toString() ?? '';
        recordData['walk'] = wType;
      }
    }


    int recordCount = 0;
    if (walkDocId.isNotEmpty) {
      final snap = await recordsCol.where('walkDocId', isEqualTo: walkDocId).get();
      recordCount = snap.docs.length;
    }


    final customId = _generateCustomId(recordData, recordCount + 1);


    await recordsCol.doc(customId).set(recordData);

    return customId;
  }


  Future<List<Map<String, dynamic>>> queryRecords({
    String? startDate,
    String? endDate,
    String? walkType,
    String? category,
  }) async {
    Query query = recordsCol;

    if (category != null && category != 'all') {
      query = query.where('category', isEqualTo: category);
    }
    if (walkType != null && walkType != 'both') {
      query = query.where('walk', isEqualTo: walkType);
    }
    if (startDate != null && startDate.isNotEmpty) {
      query = query.where('date', isGreaterThanOrEqualTo: startDate);
    }
    if (endDate != null && endDate.isNotEmpty) {
      query = query.where('date', isLessThanOrEqualTo: endDate);
    }

    final snap = await query.get();
    return snap.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final map = Map<String, dynamic>.from(data);
      map['id'] = doc.id;
      return map;
    }).toList();
  }


  String _generateCustomId(Map<String, dynamic> record, int recordNumber) {
    final dateStr = record['date']?.toString() ?? '';
    String yy = '??';
    String mm = '??';
    if (dateStr.length >= 7) {
      yy = dateStr.substring(2, 4);
      mm = dateStr.substring(5, 7);
    }

    final walkVal = record['walk']?.toString().toLowerCase() ?? '';
    String walkCode = '??';
    if (walkVal.contains('bess')) {
      walkCode = 'BN';
    } else if (walkVal.contains('mar')) {
      walkCode = 'MR';
    }

    final catVal = record['category']?.toString().toLowerCase() ?? '';
    String catCode = '??';
    if (catVal.contains('turtle_death')) {
      catCode = 'DT';
    } else if (catVal.contains('false_crawl')) {
      catCode = 'FW';
    } else if (catVal.contains('nest_find')) {
      catCode = 'NF';
    }

    const walkNumber = '00';
    final rr = recordNumber.toString().padLeft(2, '0');


    return '$yy$walkCode$catCode$mm$walkNumber$rr';
  }
}

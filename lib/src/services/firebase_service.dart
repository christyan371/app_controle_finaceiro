import 'package:cloud_firestore/cloud_firestore.dart';

// class FirebaseService {
//   static Future<double> calculateTotalValue() async {
//     final querySnapshot = await FirebaseFirestore.instance.collection('finance').get();
//     double total = 0.0;

//     for (var doc in querySnapshot.docs) {
//       final data = doc.data() as Map<String, dynamic>;
//       final value = data['value'];
//       final type = data['type'];

//       if (type == 'Receita') {
//         total += value;
//       } else if (type == 'Despesa') {
//         total -= value;
//       }
//     }

//     return double.parse(total.toStringAsFixed(2));
//   }

//   static Future<Map<DateTime, List<Map<String, dynamic>>>> loadEvents() async {
//     final querySnapshot = await FirebaseFirestore.instance.collection('finance').get();
//     Map<DateTime, List<Map<String, dynamic>>> events = {};

//     for (var doc in querySnapshot.docs) {
//       final data = doc.data() as Map<String, dynamic>;
//       Timestamp? timestamp = data['timestamp'] as Timestamp?;
//       if (timestamp == null) {
//         timestamp = Timestamp.now();
//       }
//       final date = DateTime(timestamp.toDate().year, timestamp.toDate().month, timestamp.toDate().day);

//       if (events[date] == null) {
//         events[date] = [];
//       }
//       events[date]!.add(data);
//     }

//     return events;
//   }

//   static Future<void> addData(String name, double value, String type) async {
//     await FirebaseFirestore.instance.collection('finance').add({
//       'name': name,
//       'value': value,
//       'type': type,
//       'timestamp': FieldValue.serverTimestamp(),
//     });
//   }

//   static Future<void> updateData(String id, String name, double value, String type) async {
//     final oldDoc = await FirebaseFirestore.instance.collection('finance').doc(id).get();
//     final oldData = oldDoc.data() as Map<String, dynamic>;
//     // final oldValue = oldData['value'];
//     // final oldType = oldData['type'];

//     await FirebaseFirestore.instance.collection('finance').doc(id).update({
//       'name': name,
//       'value': value,
//       'type': type,
//     });
//   }

//   static Future<void> deleteData(String id, double value, String type) async {
//     await FirebaseFirestore.instance.collection('finance').doc(id).delete();
//   }
// }

class FirebaseService {
  static Future<double> calculateTotalValue() async {
    double total = 0.0;
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('finance').get();
    for (var doc in snapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      double value = data['value'];
      String type = data['type'];
      if (type == 'Receita') {
        total += value;
      } else if (type == 'Despesa') {
        total -= value;
      }
    }
    return total;
  }

  static Future<Map<DateTime, List<Map<String, dynamic>>>> loadEvents() async {
    Map<DateTime, List<Map<String, dynamic>>> events = {};
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('finance').get();
    for (var doc in snapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      DateTime date = (data['timestamp'] as Timestamp).toDate();
      if (events[date] == null) {
        events[date] = [];
      }
      events[date]!.add(data);
    }
    return events;
  }

  static Future<void> addData(String name, double value, String type) async {
    await FirebaseFirestore.instance.collection('finance').add({
      'name': name,
      'value': value,
      'type': type,
      'timestamp': Timestamp.now(),
    });
  }

  static Future<void> updateData(String id, String name, double value, String type) async {
    await FirebaseFirestore.instance.collection('finance').doc(id).update({
      'name': name,
      'value': value,
      'type': type,
      'timestamp': Timestamp.now(),
    });
  }

  static Future<void> deleteData(String id, double value, String type) async {
    await FirebaseFirestore.instance.collection('finance').doc(id).delete();
  }
}
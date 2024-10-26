import 'package:flutter/material.dart';

class EventMarker {
  static Widget buildEventsMarker(DateTime date, List events) {
    bool hasExpense = events.any((event) => event['type'] == 'Despesa');
    bool hasIncome = events.any((event) => event['type'] == 'Receita');

    if (hasExpense && hasIncome) {
      return const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.circle, color: Colors.red, size: 8.0),
          SizedBox(width: 2),
          Icon(Icons.circle, color: Colors.green, size: 8.0),
        ],
      );
    } else if (hasExpense) {
      return const Icon(Icons.circle, color: Colors.red, size: 8.0);
    } else if (hasIncome) {
      return const Icon(Icons.circle, color: Colors.green, size: 8.0);
    } else {
      return Container();
    }
  }
}
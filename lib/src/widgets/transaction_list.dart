import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TransactionList extends StatelessWidget {
  final NumberFormat currencyFormat;
  final Set<String> selectedItems;
  final Function(String, String, double, String) onEdit;
  final Function(String, double, String) onDelete;
  final Function() onDeleteSelected;
  final DateTime? selectedDate; // Adicione esta linha

  TransactionList({
    required this.currencyFormat,
    required this.selectedItems,
    required this.onEdit,
    required this.onDelete,
    required this.onDeleteSelected,
    this.selectedDate, // Adicione esta linha
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('finance')
          .orderBy('type', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final documents = snapshot.data!.docs;

        // Filtrar transações pela data selecionada
        final filteredDocuments = selectedDate == null
            ? documents
            : documents.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final timestamp = data['timestamp'] as Timestamp?;
                final date = timestamp?.toDate();
                return date != null &&
                    date.year == selectedDate!.year &&
                    date.month == selectedDate!.month &&
                    date.day == selectedDate!.day;
              }).toList();

        final receitas = filteredDocuments
            .where((doc) => (doc.data() as Map<String, dynamic>)['type'] == 'Receita')
            .toList();
        final despesas = filteredDocuments
            .where((doc) => (doc.data() as Map<String, dynamic>)['type'] == 'Despesa')
            .toList();

        double totalReceitas = receitas.fold(0.0, (sum, doc) {
          return sum + (doc.data() as Map<String, dynamic>)['value'];
        });

        double totalDespesas = despesas.fold(0.0, (sum, doc) {
          return sum + (doc.data() as Map<String, dynamic>)['value'];
        });

        return ListView(
          children: [
            _buildTransactionCard('Receitas', totalReceitas, receitas),
            _buildTransactionCard('Despesas', totalDespesas, despesas),
          ],
        );
      },
    );
  }

  Widget _buildTransactionCard(String title, double total, List<DocumentSnapshot> transactions) {
    return Card(
      child: ExpansionTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title),
            Text('${currencyFormat.format(total)}'),
          ],
        ),
        children: transactions.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = data['name'];
          final value = data['value'];
          final type = data['type'];
          final timestamp = data['timestamp'] as Timestamp?;
          final date = timestamp?.toDate();

          return ListTile(
            leading: Checkbox(
              value: selectedItems.contains(doc.id),
              onChanged: (bool? value) {
                if (value == true) {
                  selectedItems.add(doc.id);
                } else {
                  selectedItems.remove(doc.id);
                }
              },
            ),
            title: Text(name),
            subtitle: Text(
              'Valor: ${currencyFormat.format(value)}\nData: ${date != null ? DateFormat('dd/MM/yyyy').format(date) : 'N/A'}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: selectedItems.isEmpty ? () {
                    onEdit(doc.id, name, value, type);
                  } : null,
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: selectedItems.isEmpty ? () {
                    onDelete(doc.id, value, type);
                  } : onDeleteSelected,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
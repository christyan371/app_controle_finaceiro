import 'package:flutter/material.dart';

class AddEditModal extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController valueController;
  final String type;
  final Function(String?) onTypeChanged;
  final Function() onSave;
  final Function() onCancel;

  AddEditModal({
    required this.nameController,
    required this.valueController,
    required this.type,
    required this.onTypeChanged,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Nome'),
          ),
          TextField(
            controller: valueController,
            decoration: const InputDecoration(labelText: 'Valor'),
            keyboardType: TextInputType.number,
          ),
          DropdownButton<String>(
            value: type,
            onChanged: onTypeChanged,
            items: <String>['Despesa', 'Receita']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              ElevatedButton(
                onPressed: onSave,
                child: const Text('Salvar'),
              ),
              ElevatedButton(
                onPressed: onCancel,
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
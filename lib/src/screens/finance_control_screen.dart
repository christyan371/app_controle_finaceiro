import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/transaction_list.dart';
import '../widgets/add_edit_modal.dart';

class FinanceControlPage extends StatefulWidget {
  @override
  _FinanceControlPageState createState() => _FinanceControlPageState();
}

class _FinanceControlPageState extends State<FinanceControlPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  String _type = 'Despesa';
  double _totalValue = 0.0;
  String? _editingId;
  Map<DateTime, List<Map<String, dynamic>>> _events = {};
  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  String? _userName;
  String? _userEmail;
  String? _imageUrl;

  Set<String> _selectedItems = {};

  // Adicione estas variáveis
  DateTime? _selectedDate;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _calculateTotalValue();
    _loadEvents();
    _loadUserData();
  }

  void _calculateTotalValue() async {
    double total = await FirebaseService.calculateTotalValue();
    setState(() {
      _totalValue = total;
    });
  }

  void _loadEvents() async {
    Map<DateTime, List<Map<String, dynamic>>> events =
        await FirebaseService.loadEvents();
    setState(() {
      _events = events;
    });
  }

  void _loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        _userName = userDoc['name'];
        _userEmail = user.email;
        _imageUrl = userDoc['imageUrl'];
      });
    }
  }

  void _saveData() async {
    String name = _nameController.text;
    double value = double.parse(_valueController.text);

    if (_editingId == null) {
      await FirebaseService.addData(name, value, _type);
      setState(() {
        if (_type == 'Receita') {
          _totalValue += value;
        } else if (_type == 'Despesa') {
          _totalValue -= value;
        }
      });
    } else {
      await FirebaseService.updateData(_editingId!, name, value, _type);
      setState(() {
        _editingId = null;
      });
    }

    _nameController.clear();
    _valueController.clear();
    Navigator.of(context).pop();
    _loadEvents();
  }

  Future<void> _deleteData(String id, double value, String type) async {
    bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmação'),
          content: const Text('Você tem certeza que deseja excluir este item?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Excluir'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirm) {
      await FirebaseService.deleteData(id, value, type);
      setState(() {
        if (type == 'Receita') {
          _totalValue -= value;
        } else if (type == 'Despesa') {
          _totalValue += value;
        }
      });
      _loadEvents();
    }
  }

  void _deleteSelectedData() async {
    bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmação'),
          content: const Text('Você tem certeza que deseja excluir os itens selecionados?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Excluir'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirm) {
      for (String id in _selectedItems) {
        DocumentSnapshot doc = await FirebaseFirestore.instance.collection('finance').doc(id).get();
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        double value = data['value'];
        String type = data['type'];
        await _deleteData(id, value, type);
      }
      setState(() {
        _selectedItems.clear();
      });
      _loadEvents();
    }
  }

  void _editData(String id, String name, double value, String type) {
    _nameController.text = name;
    _valueController.text = value.toString();
    _type = type;
    _editingId = id;
    _showModal();
  }

  void _cancelEdit() {
    setState(() {
      _editingId = null;
      _nameController.clear();
      _valueController.clear();
    });
    Navigator.of(context).pop();
  }

  void _showModal() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return AddEditModal(
          nameController: _nameController,
          valueController: _valueController,
          type: _type,
          onTypeChanged: (String? newValue) {
            setState(() {
              _type = newValue!;
            });
          },
          onSave: _saveData,
          onCancel: _cancelEdit,
        );
      },
    );
  }

  // Método para selecionar a data
  void _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Controle Financeiro'),
      ),
      drawer: CustomDrawer(
        userName: _userName,
        userEmail: _userEmail,
        imageUrl: _imageUrl,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            // Adicione o seletor de data aqui
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
              Text(
                'Total: ${_currencyFormat.format(_totalValue)}',
              ),
              Row(
                children: [
                Text(
                  _selectedDate == null
                    ? 'Selecione uma data'
                    : 'Data: ${_dateFormat.format(_selectedDate!)}',
                ),
                IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: _pickDate,
                ),
                ],
              ),
              ],
            ),
            Text('Total: ${_currencyFormat.format(_totalValue)}'),
            Expanded(
              child: TransactionList(
                currencyFormat: _currencyFormat,
                selectedItems: _selectedItems,
                onEdit: _editData,
                onDelete: _deleteData,
                onDeleteSelected: _deleteSelectedData,
                selectedDate: _selectedDate, // Passe a data selecionada
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showModal,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
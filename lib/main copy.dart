import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controle Financeiro',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FinanceControlPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

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
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _selectedDay = DateTime.now();
  bool _isCalendarVisible = true;

  @override
  void initState() {
    super.initState();
    _calculateTotalValue();
    _loadEvents();
  }

  void _calculateTotalValue() async {
    final querySnapshot =
        await FirebaseFirestore.instance.collection('finance').get();
    double total = 0.0;

    for (var doc in querySnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final value = data['value'];
      final type = data['type'];

      if (type == 'Receita') {
        total += value;
      } else if (type == 'Despesa') {
        total -= value;
      }
    }

    setState(() {
      _totalValue = double.parse(total.toStringAsFixed(2));
    });
  }

  void _loadEvents() async {
    final querySnapshot =
        await FirebaseFirestore.instance.collection('finance').get();
    Map<DateTime, List<Map<String, dynamic>>> events = {};

    for (var doc in querySnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      Timestamp? timestamp = data['timestamp'] as Timestamp?;
      if (timestamp == null) {
        timestamp = Timestamp.now();
      }
      final date = DateTime(timestamp.toDate().year, timestamp.toDate().month,
          timestamp.toDate().day);

      if (events[date] == null) {
        events[date] = [];
      }
      events[date]!.add(data);
    }

    setState(() {
      _events = events;
    });
  }

  void _saveData() async {
    String name = _nameController.text;
    double value = double.parse(_valueController.text);

    if (_editingId == null) {
      await FirebaseFirestore.instance.collection('finance').add({
        'name': name,
        'value': value,
        'type': _type,
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        if (_type == 'Receita') {
          _totalValue += value;
        } else if (_type == 'Despesa') {
          _totalValue -= value;
        }
      });
    } else {
      final oldDoc = await FirebaseFirestore.instance
          .collection('finance')
          .doc(_editingId)
          .get();
      final oldData = oldDoc.data() as Map<String, dynamic>;
      final oldValue = oldData['value'];
      final oldType = oldData['type'];

      await FirebaseFirestore.instance
          .collection('finance')
          .doc(_editingId)
          .update({
        'name': name,
        'value': value,
        'type': _type,
      });

      setState(() {
        if (oldType == 'Receita') {
          _totalValue -= oldValue;
        } else if (oldType == 'Despesa') {
          _totalValue += oldValue;
        }

        if (_type == 'Receita') {
          _totalValue += value;
        } else if (_type == 'Despesa') {
          _totalValue -= value;
        }

        _editingId = null;
      });
    }

    _nameController.clear();
    _valueController.clear();
    Navigator.of(context).pop();
    _loadEvents();
  }

  void _deleteData(String id, double value, String type) async {
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
      await FirebaseFirestore.instance.collection('finance').doc(id).delete();

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
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              TextField(
                controller: _valueController,
                decoration: const InputDecoration(labelText: 'Valor'),
                keyboardType: TextInputType.number,
              ),
              DropdownButton<String>(
                value: _type,
                onChanged: (String? newValue) {
                  setState(() {
                    _type = newValue!;
                  });
                },
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
                    onPressed: _saveData,
                    child: const Text('Salvar'),
                  ),
                  ElevatedButton(
                    onPressed: _cancelEdit,
                    child: const Text('Cancelar'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEventsMarker(DateTime date, List events) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Controle Financeiro'),
        actions: [
          IconButton(
            icon: Icon(_isCalendarVisible
                ? Icons.calendar_today
                : Icons.calendar_view_day),
            onPressed: () {
              setState(() {
                _isCalendarVisible = !_isCalendarVisible;
              });
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Visibility(
              visible: _isCalendarVisible,
              child: TableCalendar(
                firstDay: DateTime.utc(2010, 10, 16),
                lastDay: DateTime.utc(2030, 3, 14),
                focusedDay: _selectedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _calendarFormat = CalendarFormat.month;
                  });
                },
                eventLoader: (day) {
                  return _events[day] ?? [];
                },
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    return _buildEventsMarker(date, events);
                  },
                ),
              ),
            ),
            Text('Total: $_totalValue'),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('finance')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final documents = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: documents.length,
                    itemBuilder: (context, index) {
                      final doc = documents[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final name = data['name'];
                      final value = data['value'];
                      final type = data['type'];
                      final timestamp = data['timestamp'] as Timestamp?;
                      final date = timestamp?.toDate();

                      return ExpansionTile(
                        title: Text(name),
                        children: [
                          ListTile(
                            title: Text('Valor: $value'),
                            subtitle: Text(
                              'Tipo: $type\nData: ${date != null ? DateFormat('dd/MM/yyyy').format(date) : 'N/A'}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {
                                    _editData(doc.id, name, value, type);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () {
                                    _deleteData(doc.id, value, type);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showModal,
        child: const Icon(Icons.add),
      ),
    );
  }
}

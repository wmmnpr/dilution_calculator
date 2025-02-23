import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bottle Tracker',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: BottleHomePage(),
    );
  }
}

enum ConcentrationUnit {
  mgPerML("mg/mL"),
  ugPerML("ug/mL"),
  ngPerML("ng/mL");

  final String displayName;
  const ConcentrationUnit(this.displayName);
}

class Concentration {
  final double number;
  final ConcentrationUnit unit;

  Concentration(this.number, this.unit);
}

class Bottle {
  final String name;
  final Concentration concentration;
  Bottle(this.name, this.concentration);
}

class Dilution {
  final String amount;
  final String amountUnit;
  final Map<String, Concentration> bottleConcentrations;
  Dilution(this.amount, this.amountUnit, this.bottleConcentrations);
}

class BottleHomePage extends StatefulWidget {
  @override
  _BottleHomePageState createState() => _BottleHomePageState();
}

class _BottleHomePageState extends State<BottleHomePage> {
  final List<Bottle> bottles = [];
  final List<Dilution> dilutions = [];

  void _showAddBottleDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String name = '';
        double concentrationValue = 0;
        ConcentrationUnit unit = ConcentrationUnit.mgPerML;
        return AlertDialog(
          title: Text('Add Bottle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'Name'),
                onChanged: (value) => name = value,
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Concentration'),
                keyboardType: TextInputType.number,
                onChanged: (value) => concentrationValue = double.tryParse(value) ?? 0,
              ),
              DropdownButtonFormField<ConcentrationUnit>(
                value: unit,
                items: ConcentrationUnit.values.map((u) {
                  return DropdownMenuItem(
                    value: u,
                    child: Text(u.displayName),
                  );
                }).toList(),
                onChanged: (value) => setState(() => unit = value ?? ConcentrationUnit.mgPerML),
                decoration: InputDecoration(labelText: 'Units'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (name.isNotEmpty) {
                  setState(() {
                    bottles.add(Bottle(name, Concentration(concentrationValue, unit)));
                  });
                  Navigator.of(context).pop();
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showAddDilutionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        Map<String, double> concentrations = {};
        String amount = '';
        String amountUnit = 'mL';
        return AlertDialog(
          title: Text('Add Dilution'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                onChanged: (value) => amount = value,
              ),
              DropdownButtonFormField<String>(
                value: amountUnit,
                items: ['L', 'mL'].map((unit) {
                  return DropdownMenuItem(
                    value: unit,
                    child: Text(unit),
                  );
                }).toList(),
                onChanged: (value) => setState(() => amountUnit = value ?? 'mL'),
                decoration: InputDecoration(labelText: 'Amount Unit'),
              ),
              ...bottles.map((bottle) => Column(
                children: [
                  Text(bottle.name),
                  TextField(
                    decoration: InputDecoration(
                        labelText: 'Concentration for ${bottle.name}'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => concentrations[bottle.name] = double.tryParse(value) ?? 0,
                  ),
                ],
              )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (amount.isNotEmpty && concentrations.isNotEmpty) {
                  setState(() {
                    dilutions.add(Dilution(
                        amount,
                        amountUnit,
                        concentrations.map((bottleName, concentration) =>
                            MapEntry(bottleName, Concentration(concentration, bottles.firstWhere((b) => b.name == bottleName).concentration.unit)))));
                  });
                  Navigator.of(context).pop();
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bottle Tracker')),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _showAddBottleDialog,
                child: Text('Add Bottle'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: _showAddDilutionDialog,
                child: Text('Add Dilution'),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Concentration')),
                  DataColumn(label: Text('Unit')),
                ],
                rows: bottles.map((bottle) => DataRow(cells: [
                  DataCell(Text(bottle.name)),
                  DataCell(Text(bottle.concentration.number.toString())),
                  DataCell(Text(bottle.concentration.unit.displayName)),
                ])).toList(),
              ),
            ),
          ),
          if (dilutions.isNotEmpty) ...[
            Divider(),
          ],
        ],
      ),
    );
  }
}

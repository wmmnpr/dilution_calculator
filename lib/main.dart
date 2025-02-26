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
  mgPerML("mg/mL", 1e-3 / 1e-3),
  ugPerML("ug/mL", 1e-6 / 1e-3),
  ngPerML("ng/mL", 1e-9 / 1e-3);

  final String displayName;
  final double multiplier;

  const ConcentrationUnit(this.displayName, this.multiplier);
}

class Concentration {
  final double amount;
  final ConcentrationUnit unit;

  Concentration(this.amount, this.unit);

  @override
  String toString() {
    var units = unit.displayName;
    return '$amount $units';
  }
}

enum VolumeUnits {
  l("L", 1),
  ml("mL", 1e-3),
  ul("uL", 1e-9);

  final String displayName;
  final double multiplier;

  const VolumeUnits(this.displayName, this.multiplier);
}

class Volume {
  final double amount;
  final VolumeUnits units;

  Volume(this.amount, this.units);

  @override
  String toString() {
    var displayName = units.displayName;
    return '$amount $displayName';
  }
}

class Bottle {
  final String name;
  final Concentration concentration;

  Bottle(this.name, this.concentration);
}

class Dilution {
  final Volume volume;
  final Map<String, Concentration> bottleConcentrations;

  Dilution(this.volume, this.bottleConcentrations);
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
                onChanged: (value) =>
                    concentrationValue = double.tryParse(value) ?? 0,
              ),
              DropdownButtonFormField<ConcentrationUnit>(
                value: unit,
                items: ConcentrationUnit.values.map((u) {
                  return DropdownMenuItem(
                    value: u,
                    child: Text(u.displayName),
                  );
                }).toList(),
                onChanged: (value) =>
                    setState(() => unit = value ?? ConcentrationUnit.mgPerML),
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
                    bottles.add(
                        Bottle(name, Concentration(concentrationValue, unit)));
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

  bool containsNumber(String input) {
    final RegExp regex = RegExp(r'\d+(\.\d+)?');
    return regex.hasMatch(input);
  }
  void _showAddDilutionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        Map<String, Concentration> concentrations = {};
        String amount = '';
        String amountUnit = 'mL';
        double concentrationValue = 0;
        ConcentrationUnit unit = ConcentrationUnit.mgPerML;
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
                onChanged: (value) =>
                    setState(() => amountUnit = value ?? 'mL'),
                decoration: InputDecoration(labelText: 'Amount Unit'),
              ),
              ...bottles.map((bottle) => Column(
                    children: [
                      Text(bottle.name),
                      TextField(
                          decoration: InputDecoration(
                              labelText: 'Concentration for ${bottle.name}'),
                          keyboardType: TextInputType.number,
                          onChanged: (value) => {
                            if(containsNumber(value))
                                concentrations[bottle.name] = Concentration(
                                    double.tryParse(value)!,
                                    ConcentrationUnit.mgPerML)
                              }),
                      DropdownButtonFormField<ConcentrationUnit>(
                        value: unit,
                        items: ConcentrationUnit.values.map((u) {
                          return DropdownMenuItem(
                            value: u,
                            child: Text(u.displayName),
                          );
                        }).toList(),
                        onChanged: (value) => {
                          if (concentrations.containsKey(bottle.name) &&
                              bottle.name.isNotEmpty)
                            {
                              concentrations[bottle.name] = Concentration(
                                  concentrations[bottle.name]!.amount, value!),
                              setState(() =>
                                  unit = value ?? ConcentrationUnit.mgPerML)
                            }
                        },
                        decoration: InputDecoration(labelText: 'Units'),
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
                        Volume(double.parse(amount),
                            VolumeUnits.values.first /*amountUnit*/),
                        concentrations.map((bottleName, concentration) =>
                            MapEntry(bottleName, concentration))));
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
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Concentration')),
                ],
                rows: bottles
                    .map((bottle) => DataRow(cells: [
                          DataCell(Text(bottle.name)),
                          DataCell(Text(bottle.concentration.toString())),
                        ]))
                    .toList(),
              ),
            ),
          ),
          if (dilutions.isNotEmpty) ...[
            Divider(),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(label: Text('Volume')),
                    ...bottles.map(
                        (bottle) => DataColumn(label: Text('${bottle.name}'))),
                  ],
                  rows: dilutions
                      .map((dilution) => DataRow(cells: [
                            DataCell(Text(dilution.volume.toString())),
                            ...bottles.map((bottle) => DataCell(Text(dilution
                                    .bottleConcentrations[bottle.name]
                                    ?.toString() ??
                                ''))),
                          ]))
                      .toList(),
                ),
              ),
            ),
          ],
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _showAddBottleDialog,
            child: Icon(Icons.add),
            heroTag: 'addBottle',
          ),
          SizedBox(width: 10),
          FloatingActionButton(
            onPressed: _showAddDilutionDialog,
            child: Icon(Icons.science),
            heroTag: 'addDilution',
          ),
        ],
      ),
    );
  }
}

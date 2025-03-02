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
  double amount = 0.0;
  VolumeUnits units = VolumeUnits.ml;

  Volume(this.amount, this.units);

  @override
  String toString() {
    var displayName = units.displayName;
    return '$amount $displayName';
  }
}

class Solution {
  final String name;
  final Concentration concentration;

  Solution(this.name, this.concentration);
}

class Dilutant {
  final Solution solution;
  late Volume volume = Volume(0.0, VolumeUnits.ml);
  Concentration concentration;

  Dilutant(this.solution, this.concentration);
}

class Dilution {
  final Volume volume;
  final Map<String, Concentration> concentrations;
  final Map<String, Dilutant> dilutants;

  Dilution(this.volume, this.concentrations, this.dilutants);
}

class BottleHomePage extends StatefulWidget {
  @override
  _BottleHomePageState createState() => _BottleHomePageState();
}

class _BottleHomePageState extends State<BottleHomePage> {
  final Map<String, Solution> solutions = <String, Solution>{};
  final List<Dilution> dilutions = [];

  void _showAddSolutionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String name = '';
        double concentrationValue = 0;
        ConcentrationUnit unit = ConcentrationUnit.mgPerML;
        return AlertDialog(
          title: Text('Add Solution'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'Solution'),
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
                    solutions.putIfAbsent(
                        name,
                        () => Solution(
                            name, Concentration(concentrationValue, unit)));
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

  void _calculateDilutions() {
    for (var dil in this.dilutions) {}
  }

  bool containsNumber(String input) {
    final RegExp regex = RegExp(r'\d+(\.\d+)?');
    return regex.hasMatch(input);
  }

  void _showAddDilutionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        Map<String, Concentration> concentrations = <String, Concentration>{};
        String amount = '';
        String amountUnit = 'mL';
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
              ...solutions.entries.map((bottle) => Column(
                    children: [
                      Text(bottle.key),
                      TextField(
                          decoration: InputDecoration(
                              labelText: 'Concentration for ${bottle.key}'),
                          keyboardType: TextInputType.number,
                          onChanged: (value) => {
                                if (containsNumber(value))
                                  concentrations[bottle.key] = Concentration(
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
                          if (concentrations.containsKey(bottle.key) &&
                              bottle.key.isNotEmpty)
                            {
                              concentrations[bottle.key] = Concentration(
                                  concentrations[bottle.key]!.amount, value!),
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
                    Map<String, Dilutant> dilutants = <String, Dilutant>{};
                    concentrations.forEach((name, conc) => {
                          dilutants.putIfAbsent(
                              name, () => Dilutant(solutions[name]!, conc))
                        });
                    dilutions.add(Dilution(
                        Volume(
                            double.parse(amount),
                            VolumeUnits.values.firstWhere((unit) =>
                                unit.displayName.compareTo(amountUnit) == 0)),
                        concentrations,
                        dilutants));
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
      appBar: AppBar(title: Text('Dilution Calculator')),
      body: Column(
        children: [
          if (solutions.isNotEmpty) ...[
            Divider(),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(label: Text('Solution')),
                    DataColumn(label: Text('Concentration')),
                  ],
                  rows: solutions.entries
                      .map((bottle) => DataRow(cells: [
                            DataCell(Text(bottle.key)),
                            DataCell(
                                Text(bottle.value.concentration.toString())),
                          ]))
                      .toList(),
                ),
              ),
            ),
          ],
          if (dilutions.isNotEmpty) ...[
            Divider(),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(label: Text('Volume')),
                    ...dilutions.first.dilutants.entries.expand((dilution) => [
                          DataColumn(
                              label: SizedBox(
                                  child: Text(
                                      textAlign: TextAlign.center,
                                      'Conc.\n${dilution.key}'))),
                          DataColumn(
                              label: SizedBox(
                                  child: Text(
                                      textAlign: TextAlign.center,
                                      'Vol.\n${dilution.key}')))
                        ]),
                  ],
                  rows: [
                    ...dilutions
                        .map((dilution) => DataRow(cells: [
                              DataCell(Text(dilution.volume.toString())),
                              ...dilution.dilutants.entries.expand((dilutant) =>
                                  [
                                    DataCell(Text(dilutant.value.concentration
                                        .toString())),
                                    DataCell(
                                        Text(dilutant.value.volume.toString()))
                                  ])
                            ]))
                        .toList(),
                  ],
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
            onPressed: _showAddSolutionDialog,
            child: Icon(Icons.add),
            heroTag: 'addBottle',
          ),
          SizedBox(width: 10),
          FloatingActionButton(
            onPressed: _showAddDilutionDialog,
            child: Icon(Icons.science),
            heroTag: 'addDilution',
          ),
          SizedBox(width: 10),
          FloatingActionButton(
            onPressed: _calculateDilutions,
            child: Icon(Icons.calculate),
            heroTag: 'calculate',
          ),
        ],
      ),
    );
  }
}

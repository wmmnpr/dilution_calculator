import 'package:flutter/material.dart';
import 'calc.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dilution Calculator',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: BottleHomePage(),
    );
  }
}



class BottleHomePage extends StatefulWidget {
  @override
  _BottleHomePageState createState() => _BottleHomePageState();
}

class _BottleHomePageState extends State<BottleHomePage> {
  final Map<String, Solution> solutions = <String, Solution>{};
  final List<Dilution> dilutions = [];


  _BottleHomePageState() {
    solutions.putIfAbsent(WATER,
        () => Solution(WATER, Concentration(0.0, ConcentrationUnit.mgPerML)));
  }

  void _calculateDilutions() {

    List<double>stockConcentrations = extractStockConcentrations(solutions);

    List<List<double>> stockMatrix = createStockMatrix(stockConcentrations);

    List<double>volumeVector = extractDilutionConcentrations(dilutions.first);

    List<List<double>>matrixBb = [volumeVector];
    List<double>? volumes = solveIt(stockMatrix, matrixBb);

    if (volumes != null) {
      for (int i = 0; i < volumes.length -1; i++) {
        dilutions.first.dilutants.values.elementAt(i).volume.amount = volumes[i];
        dilutions.first.dilutants.values.elementAt(i).volume.units = VolumeUnits.l;
        print("Use ${volumes[i].toStringAsFixed(2)} mL of Stock ${i + 1}");
      }
    } else {
      print("No valid solution: check concentrations and target values.");
    }
    setState(() => 1);
  }
  void _showAddSolutionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String name = '';
        double concentrationValue = 0;
        ConcentrationUnit unit = ConcentrationUnit.mgPerML;
        return AlertDialog(
          title: Text('Add Solution'),
          content: SingleChildScrollView(
              child: Column(
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
          )),
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
          content: SingleChildScrollView(
              child: Column(
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
              ...solutions.entries.where((test) => test.key.compareTo('H\u20820') != 0).map((bottle) => Column(
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
          )),
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

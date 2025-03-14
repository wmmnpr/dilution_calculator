import 'package:flutter/material.dart';

import 'add_solution_dialog.dart';
import 'calc.dart';
import 'dilution_scroll_view.dart';

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
    solutions.putIfAbsent(WATER, () => STOCK_WATER);
  }

  void _calculateDilutions() {
    List<double> stockConcentrations = extractStockConcentrations(solutions);

    List<List<double>> stockMatrix = createStockMatrix(stockConcentrations);

    List<double> volumeVector = extractDilutionConcentrations(dilutions.first);

    List<List<double>> matrixBb = [volumeVector];
    List<double>? volumes = solveIt(stockMatrix, matrixBb);

    VolumeUnits targetVolume = dilutions.first.volume.units;
    if (volumes != null) {
      for (int i = 0; i < volumes.length - 1; i++) {
        dilutions.first.dilutants.values.elementAt(i).volume.amount =
            volumes[i] / targetVolume.multiplier;
        dilutions.first.dilutants.values.elementAt(i).volume.units =
            targetVolume;
        print("Use ${volumes[i].toStringAsFixed(4)} mL of Stock ${i + 1}");
      }
      dilutions.first.dilutants.putIfAbsent(
          WATER,
          () => Dilutant.n(
              STOCK_WATER,
              Concentration(0.0, ConcentrationUnit.mgPerML),
              Volume(volumes.last / targetVolume.multiplier, targetVolume)));
    } else {
      print("No valid solution: check concentrations and target values.");
    }
    setState(() => 1);
  }

  void _showAddSolutionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AddSolutionDialog(
          solutions: solutions,
          title: "Add Solution",
          onConfirm: ()=>{
            setState(() {
            })
          }
        );
      },
    );
  }

  bool _containsNumber(String input) {
    final RegExp regex = RegExp(r'\d+(\.\d+)?');
    return regex.hasMatch(input);
  }

  void _deleteAllStock() {
    dilutions.clear();
    solutions.removeWhere((key, solution) => solution.name != WATER);
    setState(() {});
  }

  void _deleteAllDilutions() {
    dilutions.clear();
    setState(() {});
  }

  void _diluteDilutionBy(int dilutionListIndex) async {
    Dilution dilution = dilutions.elementAt(dilutionListIndex);

    Dilution copy = dilution.copy();
    dilutions.add(copy);

    print("select is: ${dilution.volume}");
    double? result = await showDialog<double>(
      context: context,
      builder: (context) => DiluteByInputDialog(),
    );

    if (result != null) {
      setState(() {
        //_inputValue = result;
      });
    }
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
                items: VolumeUnits.values.map((unit) {
                  return DropdownMenuItem(
                    value: unit.displayName,
                    child: Text(unit.displayName),
                  );
                }).toList(),
                onChanged: (value) =>
                    setState(() => amountUnit = value ?? 'mL'),
                decoration: InputDecoration(labelText: 'Amount Unit'),
              ),
              ...solutions.entries
                  .where((test) => test.key.compareTo('H\u20820') != 0)
                  .map((bottle) => Column(
                        children: [
                          Text(bottle.key),
                          TextField(
                              decoration: InputDecoration(
                                  labelText: 'Concentration for ${bottle.key}'),
                              keyboardType: TextInputType.number,
                              onChanged: (value) => {
                                    if (_containsNumber(value))
                                      concentrations[bottle.key] =
                                          Concentration(double.tryParse(value)!,
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
                                      concentrations[bottle.key]!.amount,
                                      value!),
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
              child: ListView(
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    FloatingActionButton(
                      onPressed: _showAddSolutionDialog,
                      child: Icon(Icons.add),
                      heroTag: 'addStock',
                    ),
                    SizedBox(width: 10),
                    FloatingActionButton(
                      onPressed: _deleteAllStock,
                      child: Icon(Icons.delete),
                      heroTag: 'Delete All',
                    )
                  ]),
                  Center(
                      child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Stock')),
                        DataColumn(label: Text('Concentration')),
                      ],
                      rows: solutions.entries
                          .map((bottle) => DataRow(cells: [
                                DataCell(Text(bottle.key)),
                                DataCell(Text(
                                    bottle.value.concentration.toString())),
                              ]))
                          .toList(),
                    ),
                  ))
                ],
              ),
            )
          ],
          if (dilutions.isNotEmpty) ...[
            Divider(),
            Expanded(
              child: DilutionScrollViewScrollView(
                  dilutions: dilutions, onDiluteBy: _diluteDilutionBy),
            ),
          ],
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FloatingActionButton(
            onPressed: _showAddDilutionDialog,
            child: Icon(Icons.add),
            heroTag: 'addDilution',
          ),
          if (dilutions.isNotEmpty) ...[
            SizedBox(width: 10),
            FloatingActionButton(
              onPressed: _deleteAllDilutions,
              child: Icon(Icons.delete),
              heroTag: 'Delete All',
            ),
            SizedBox(width: 10),
            FloatingActionButton(
              onPressed: _calculateDilutions,
              child: Icon(Icons.calculate),
              heroTag: 'calculate',
            )
          ],
        ],
      ),
    );
  }
}

class DiluteByInputDialog extends StatefulWidget {
  @override
  _DiluteByInputDialogState createState() => _DiluteByInputDialogState();
}

class _DiluteByInputDialogState extends State<DiluteByInputDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _errorMessage;

  void _submit() {
    double? value = double.tryParse(_controller.text);
    if (value == null) {
      setState(() {
        _errorMessage = "Please enter a valid number";
      });
      return;
    }

    Navigator.of(context).pop(value); // Return the entered double
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Dilute by factor"),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: "Number",
          errorText: _errorMessage,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          // Close without returning
          child: Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text("OK"),
        ),
      ],
    );
  }
}

import 'package:dilution_calculator/add_dilution_dialog.dart';
import 'package:flutter/material.dart';

import 'add_solution_dialog.dart';
import 'calc.dart';
import 'dilute_by_dialog.dart';
import 'dilution_view.dart';

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
        //print("Use ${volumes[i].toStringAsFixed(4)} mL of Stock ${i + 1}");
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
            onConfirm: () => {setState(() {})});
      },
    );
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

  Dilution _createDilution(final Dilution dilution, final String dilutantName,
      double dilutionFactor) {
    Map<String, Concentration> concentrations = dilution.concentrations.map(
        (k, v) =>
            MapEntry(k, Concentration(v.amount / dilutionFactor, v.unit)));
    Map<String, Dilutant> dilutants = <String, Dilutant>{};

    double totalSolutes = dilution.dilutants.values.fold(
        0.0,
        (sum, v) =>
            sum +
            (v.concentration.amount *
                v.concentration.unit.multiplier *
                v.volume.amount *
                v.volume.units.multiplier));

    double totalVolume = dilution.dilutants.values.fold(
        0.0, (sum, v) => sum + v.volume.amount * v.volume.units.multiplier);

    double concMgPerML = totalSolutes / totalVolume;

    Solution solution = Solution(
        dilutantName, Concentration(concMgPerML, ConcentrationUnit.mgPerML));
    //solutions.putIfAbsent(dilutantName, () => solution);
    dilutants.putIfAbsent(
        dilutantName,
        () =>
            Dilutant.n(solution, Concentration(concMgPerML, ConcentrationUnit.mgPerML), Volume(dilution.volume.amount/dilutionFactor, dilution.volume.units)));
    dilutants.putIfAbsent(
        WATER,
        () => Dilutant.n(
            STOCK_WATER, Concentration(0.0, ConcentrationUnit.mgPerML),Volume(dilution.volume.amount - dilution.volume.amount/dilutionFactor, dilution.volume.units)));
    Dilution newDilution = Dilution(
        volume: dilution.volume.copy(),
        concentrations: concentrations,
        dilutants: dilutants);

    newDilution.dilutionType = DilutionType.SERIAL;
    return newDilution;
  }

  void _diluteDilutionBy(String action, int dilutionListIndex) async {
    if (action == 'delete') {
      dilutions.removeAt(dilutionListIndex);
    } else {
      double? result = await showDialog<double>(
        context: context,
        builder: (context) => DiluteByInputDialog(),
      );
      if (result! > 1.0) {
        Dilution dilution = dilutions.elementAt(dilutionListIndex);
        String dilutantName = "d_$dilutionListIndex";
        Dilution dilutionNew = _createDilution(dilution, dilutantName, result);
        dilutions.add(dilutionNew);
      }
    }

    setState(() {
      //_inputValue = result;
    });
  }

  void _showAddDilutionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AddDilutionDialog(
          solutions: solutions,
          dilutions: dilutions,
          onConfirm: () {
            setState(() {});
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dilution Calculator')),
      body: Column(
        children: [
          if (solutions.isNotEmpty) ...[
            const Divider(),
            Expanded(
              child: ListView(
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    FloatingActionButton(
                      onPressed: _showAddSolutionDialog,
                      child: const Icon(Icons.add),
                      heroTag: 'addStock',
                    ),
                    const SizedBox(width: 10),
                    FloatingActionButton(
                      onPressed: _deleteAllStock,
                      child: const Icon(Icons.delete),
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
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  children: dilutions
                      .asMap()
                      .entries
                      .map((dilutionEntry) => Expanded(
                            child: SimpleDilutionDataTable(
                              dilutionIndex: dilutionEntry.key,
                              dilutions: [dilutionEntry.value],
                              // Pass a list with a single element
                              onDiluteBy: _diluteDilutionBy,
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
          ],
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FloatingActionButton(
            onPressed: _showAddDilutionDialog,
            child: const Icon(Icons.add),
            heroTag: 'addDilution',
          ),
          if (dilutions.isNotEmpty) ...[
            const SizedBox(width: 10),
            FloatingActionButton(
              onPressed: _deleteAllDilutions,
              heroTag: 'Delete All',
              child: const Icon(Icons.delete),
            ),
            const SizedBox(width: 10),
            FloatingActionButton(
              onPressed: _calculateDilutions,
              heroTag: 'calculate',
              child: const Icon(Icons.calculate),
            )
          ],
        ],
      ),
    );
  }
}

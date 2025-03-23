import 'package:dilution_calculator/add_dilution_dialog.dart';
import 'package:dilution_calculator/dilute_by_custom_dialog.dart';
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
    solutions.putIfAbsent(WATER,
        () => Solution(WATER, Concentration(0.0, ConcentrationUnit.mgPerML)));
    solutions.putIfAbsent('a',
        () => Solution('a', Concentration(10.0, ConcentrationUnit.mgPerML)));
    solutions.putIfAbsent('b',
        () => Solution('b', Concentration(5.0, ConcentrationUnit.mgPerML)));
  }

  void _calculateDilutions() {
    calculateDilutionFrom(dilutions.first, solutions);
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

  Dilution _createStepDilution(final Dilution dilution, double dilutionFactor) {
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

    Solution solution = Solution(dilution.getWorkingName(),
        Concentration(concMgPerML, ConcentrationUnit.mgPerML));
    //solutions.putIfAbsent(dilutantName, () => solution);
    dilutants.putIfAbsent(
        dilution.getWorkingName(),
        () => Dilutant.n(
            solution,
            Concentration(concMgPerML, ConcentrationUnit.mgPerML),
            Volume(dilution.volume.amount / dilutionFactor,
                dilution.volume.units)));
    dilutants.putIfAbsent(
        WATER,
        () => Dilutant.n(
            STOCK_WATER,
            Concentration(0.0, ConcentrationUnit.mgPerML),
            Volume(
                dilution.volume.amount -
                    dilution.volume.amount / dilutionFactor,
                dilution.volume.units)));
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
    } else if (action == 'diluteBy') {
      double? result = await showDialog<double>(
        context: context,
        builder: (context) => DiluteByInputDialog(),
      );
      if (result! > 1.0) {
        Dilution dilution = dilutions.elementAt(dilutionListIndex);
        Dilution stepDilution = _createStepDilution(dilution, result);

        stepDilution.dilutants.forEach((k, dilutant) {
          if (dilutant.solution.name != WATER) {
            Dilution recalc = dilutions.elementAt(int.parse(k.substring(2)));
            double origVol =
                recalc.volume.amount * recalc.volume.units.multiplier;
            double extraVol =
                dilutant.volume.amount * dilutant.volume.units.multiplier;
            recalc.volume = Volume(
                (origVol + extraVol) / VolumeUnits.ml.multiplier,
                VolumeUnits.ml);
            calculateDilutionFrom(recalc, solutions);
          }
        });

        dilutions.add(stepDilution);
      }
    } else if (action == "diluteByCustom") {
      Dilution dilutant = dilutions.elementAt(dilutionListIndex);
      _showAddDiluteByCustomDialog(dilutant);
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

  void _showAddDiluteByCustomDialog(Dilution dilutant) {
    List<Dilution> dilutions = <Dilution>[];
    Map<String, Solution> extendSolutions = <String, Solution>{};
    showDialog(
      context: context,
      builder: (context) {
        return DiluteByCustomDialog(
          solutions: solutions,
          dilutions: dilutions,
          onConfirm: () {
            for (var dil in dilutions) {
              print(dil.toString());
            }
            extendSolutions.addAll(solutions);
            //create solution from dilution
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

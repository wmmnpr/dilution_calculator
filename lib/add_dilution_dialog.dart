import 'package:flutter/material.dart';

import 'calc.dart';

class AddDilutionDialog extends StatelessWidget {
  final Map<String, Solution> solutions;
  final List<Dilution> dilutions;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  String amount = '';
  String amountUnit = 'mL';
  ConcentrationUnit unit = ConcentrationUnit.mgPerML;

  AddDilutionDialog(
      {super.key,
      required this.solutions,
      required this.dilutions,
      required this.onConfirm,
      this.onCancel});

  @override
  Widget build(BuildContext context) {
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
            onChanged: (value) => {amountUnit = value ?? 'mL'},
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
                              this.unit = value ?? ConcentrationUnit.mgPerML
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
              onConfirm();
              Navigator.of(context).pop();
            }
          },
          child: Text('Add'),
        ),
      ],
    );
  }
}

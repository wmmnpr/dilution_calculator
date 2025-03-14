import 'package:flutter/material.dart';

import 'calc.dart';

class AddSolutionDialog extends StatelessWidget {
  final String title;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final Map<String, Solution> solutions;

  const AddSolutionDialog(
      {Key? key,
      required this.solutions,
      required this.title,
      required this.onConfirm,
      this.onCancel})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
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
            onChanged: (value) => unit = value ?? ConcentrationUnit.mgPerML,
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
              solutions.putIfAbsent(
                  name,
                  () =>
                      Solution(name, Concentration(concentrationValue, unit)));
              onConfirm();
              Navigator.of(context).pop();
            }
          },
          child: Text('Add'),
        ),
      ],
    );
    ;
  }
}

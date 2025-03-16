import 'package:flutter/material.dart';

import 'calc.dart';

class SimpleDilutionDataTable extends StatelessWidget {
  final EdgeInsets padding;
  final ScrollPhysics? physics;
  final int dilutionIndex;
  final List<Dilution> dilutions;
  final void Function(int) onDiluteBy;

  const SimpleDilutionDataTable(
      {super.key,
      required this.dilutionIndex,
      required this.dilutions,
      required this.onDiluteBy,
      this.padding = const EdgeInsets.all(8.0),
      this.physics});

  @override
  Widget build(BuildContext context) {
    return DataTable(
      columns: [
        const DataColumn(label: Text(textAlign: TextAlign.center, 'Dil.\nId')),
        const DataColumn(label: Text(textAlign: TextAlign.center, 'Volume')),
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
        const DataColumn(
            label:
                SizedBox(child: Text(textAlign: TextAlign.center, 'Action'))),
      ],
      rows: [
        ...dilutions
            .asMap()
            .entries
            .map((dilution) => DataRow(cells: [
                  DataCell(
                      Text(textAlign: TextAlign.center, 'd_${dilutionIndex}')),
                  DataCell(Text(dilution.value.volume.toString())),
                  ...dilution.value.dilutants.entries.expand((dilutant) => [
                        DataCell(Text(dilutant.value.concentration.toString())),
                        DataCell(Text(dilutant.value.volume.toString()))
                      ]),
                  DataCell(
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'diluteBy') {
                          onDiluteBy(dilutionIndex);
                        } else if (value == 'delete') {
                          print('Delete');
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                            value: 'diluteBy', child: Text('Dilute by ...')),
                        const PopupMenuItem(
                            value: 'delete', child: Text('Delete')),
                      ],
                      child: const Icon(Icons.more_vert), // Three-dot menu
                    ),
                  )
                ]))
            .toList(),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import 'calc.dart';

class SimpleDilutionDataTable extends StatelessWidget {
  final EdgeInsets padding;
  final ScrollPhysics? physics;
  final int dilutionIndex;
  final List<Dilution> dilutions;
  final void Function(String, int) onDiluteBy;

  const SimpleDilutionDataTable(
      {super.key,
      required this.dilutionIndex,
      required this.dilutions,
      required this.onDiluteBy,
      this.padding = const EdgeInsets.all(8.0),
      this.physics});

  @override
  Widget build(BuildContext context) {
    if (dilutions.first.dilutionType == DilutionType.SERIAL) {
      return DataTable(columns: [
        const DataColumn(label: Text(textAlign: TextAlign.center, 'Dil.\nId')),
        const DataColumn(label: Text(textAlign: TextAlign.center, 'Volume')),
        ...dilutions.first.concentrations.entries.expand((conc) => [
              DataColumn(
                  label: SizedBox(
                      child: Text(
                          textAlign: TextAlign.center, 'Conc.\n${conc.key}'))),
            ]),
        ...dilutions.first.dilutants.entries.expand((dilutant) => [
          DataColumn(
              label: SizedBox(
                  child: Text(
                      textAlign: TextAlign.center, 'Vol.\n${dilutant.key}')))
        ]),
        const DataColumn(
            label:
                SizedBox(child: Text(textAlign: TextAlign.center, 'Action'))),
      ], rows: [
        ...dilutions
            .asMap()
            .entries
            .map((dilution) => DataRow(cells: [
                  DataCell(
                      Text(textAlign: TextAlign.center, 'd_${dilutionIndex}')),
                  DataCell(Text(dilution.value.volume.toString())),
                  ...dilution.value.concentrations.entries.expand((conc) => [
                        DataCell(Text(conc.value.toString())),
                      ]),
                  ...dilution.value.dilutants.entries.expand((dilutant) => [
                        DataCell(Text(dilutant.value.volume.toString())),
                      ]),
                  DataCell(
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        onDiluteBy(value, dilutionIndex);
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
      ]);
    } else {
      return DataTable(
        columns: [
          const DataColumn(
              label: Text(textAlign: TextAlign.center, 'Dil.\nId')),
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
                    DataCell(Text(
                        textAlign: TextAlign.center, 'd_${dilutionIndex}')),
                    DataCell(Text(dilution.value.volume.toString())),
                    ...dilution.value.dilutants.entries.expand((dilutant) => [
                          DataCell(
                              Text(dilutant.value.concentration.toString())),
                          DataCell(Text(dilutant.value.volume.toString()))
                        ]),
                    DataCell(
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          onDiluteBy(value, dilutionIndex);
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                              value: 'diluteBy', child: Text('Dilute by ...')),
                          const PopupMenuItem(
                              value: 'diluteByCustom', child: Text('Dilute by custom ...')),
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
}

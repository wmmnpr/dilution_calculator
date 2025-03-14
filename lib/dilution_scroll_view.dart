import 'package:flutter/material.dart';

import 'calc.dart';

class DilutionScrollViewScrollView extends StatelessWidget {
  final EdgeInsets padding;
  final ScrollPhysics? physics;
  final List<Dilution> dilutions;
  final void Function(int) onDiluteBy;


  const DilutionScrollViewScrollView({
    Key? key,
    required this.dilutions,
    required this.onDiluteBy,
    this.padding = const EdgeInsets.all(8.0),
    this.physics
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
          const DataColumn(
              label: SizedBox(
                  child:
                  Text(textAlign: TextAlign.center, 'Action'))),
        ],
        rows: [
          ...dilutions
              .asMap()
              .entries
              .map((dilution) => DataRow(cells: [
            DataCell(Text(dilution.value.volume.toString())),
            ...dilution.value.dilutants.entries
                .expand((dilutant) => [
              DataCell(Text(dilutant
                  .value.concentration
                  .toString())),
              DataCell(Text(
                  dilutant.value.volume.toString()))
            ]),
            DataCell(
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'diluteBy') {
                    onDiluteBy(dilution.key);
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
                child: const Icon(
                    Icons.more_vert), // Three-dot menu
              ),
            )
          ]))
              .toList(),
        ],
      ),
    );
  }
}
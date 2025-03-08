import 'package:dilution_calculator/main.dart';
import 'package:test/test.dart';
import 'package:dilution_calculator/calc.dart';

void main() {
  group('data conversion', ()
  {
    setUp(() {
      // Additional setup goes here.
    });

    test('single stock solution', () {

      final Map<String, Solution> solutions = <String, Solution>{};
      solutions.putIfAbsent(WATER,
              () => Solution(WATER, Concentration(0.0, ConcentrationUnit.mgPerML)));
      solutions.putIfAbsent('a',
              () => Solution('a', Concentration(16.0, ConcentrationUnit.mgPerML)));
      
      final List<Dilution> dilutions = <Dilution>[];
      
      Map<String, Concentration>concentrations = <String, Concentration>{};
      concentrations.putIfAbsent('a', () => Concentration(16, ConcentrationUnit.mgPerML));
      Map<String, Dilutant>dilutants = <String, Dilutant>{};
      dilutants.putIfAbsent('a', () => Dilutant(solutions.values.elementAt(1), Concentration(0.5, ConcentrationUnit.mgPerML)));
      dilutions.add(Dilution(Volume(8.0, VolumeUnits.l), concentrations, dilutants));

      List<double> stockConcentrations = extractStockConcentrations(solutions);
      List<List<double>> stockMatrix = createStockMatrix(stockConcentrations);

      List<double>dilutionConcentrations = extractDilutionConcentrations(dilutions.first);
      List<List<double>>dilutionVector = [dilutionConcentrations];

      List<double>finalDilutantVolumes = solveIt(stockMatrix, dilutionVector);


      print(finalDilutantVolumes);
      expect(finalDilutantVolumes, [0.25, 7.75]);


    });

    test('double stock solution', () {

      final Map<String, Solution> stockSolutions = <String, Solution>{};
      stockSolutions.putIfAbsent(WATER,
              () => Solution(WATER, Concentration(0.0, ConcentrationUnit.mgPerML)));
      stockSolutions.putIfAbsent('a',
              () => Solution('a', Concentration(16.0, ConcentrationUnit.mgPerML)));
      stockSolutions.putIfAbsent('b',
              () => Solution('b', Concentration(16.0, ConcentrationUnit.mgPerML)));

      final List<Dilution> dilutions = <Dilution>[];
      Map<String, Concentration>concentrations = <String, Concentration>{};
      concentrations.putIfAbsent('a', () => Concentration(16, ConcentrationUnit.mgPerML));
      concentrations.putIfAbsent('b', () => Concentration(16, ConcentrationUnit.mgPerML));

      Map<String, Dilutant>dilutants = <String, Dilutant>{};
      dilutants.putIfAbsent('a', () => Dilutant(stockSolutions.values.elementAt(1), Concentration(0.5, ConcentrationUnit.mgPerML)));
      dilutants.putIfAbsent('b', () => Dilutant(stockSolutions.values.elementAt(1), Concentration(1.0, ConcentrationUnit.mgPerML)));
      dilutions.add(Dilution(Volume(20.0, VolumeUnits.l), concentrations, dilutants));

      List<double> stockConcentrations = extractStockConcentrations(stockSolutions);
      List<List<double>> stockMatrix = createStockMatrix(stockConcentrations);

      List<double>dilutionConcentrations = extractDilutionConcentrations(dilutions.first);
      List<List<double>>dilutionVector = [dilutionConcentrations];

      List<double>finalDilutantVolumes = solveIt(stockMatrix, dilutionVector);


      print(finalDilutantVolumes);
      expect(finalDilutantVolumes, [0.625, 1.25, 18.125]);


    });
  });
}
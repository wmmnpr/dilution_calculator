import 'package:dilution_calculator/calc.dart';
import 'package:equations/equations.dart';
import 'package:test/test.dart';

void main() {
  group('data conversion', () {
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

      Map<String, Concentration> concentrations = <String, Concentration>{};
      concentrations.putIfAbsent(
          'a', () => Concentration(16, ConcentrationUnit.mgPerML));
      Map<String, Dilutant> dilutants = <String, Dilutant>{};
      dilutants.putIfAbsent(
          'a',
          () => Dilutant(solutions.values.elementAt(1),
              Concentration(0.5, ConcentrationUnit.mgPerML)));
      dilutions.add(Dilution(
          volume: Volume(8.0, VolumeUnits.l),
          concentrations: concentrations,
          dilutants: dilutants));

      List<double> stockConcentrations = extractStockConcentrations(solutions);
      List<List<double>> stockMatrix = createStockMatrix(stockConcentrations);

      List<double> dilutionConcentrations =
          extractDilutionConcentrations(dilutions.first);
      List<List<double>> dilutionVector = [dilutionConcentrations];

      List<double> finalDilutantVolumes = solveIt(stockMatrix, dilutionVector);

      print(finalDilutantVolumes);
      expect(finalDilutantVolumes, [0.25, 7.75]);
    });

    test('test step with domain objects', () {
      final Map<String, Solution> stockSolutions = <String, Solution>{};
      stockSolutions.putIfAbsent(WATER,
          () => Solution(WATER, Concentration(0.0, ConcentrationUnit.mgPerML)));
      stockSolutions.putIfAbsent('a',
          () => Solution('a', Concentration(10.0, ConcentrationUnit.mgPerML)));
      stockSolutions.putIfAbsent('b',
          () => Solution('b', Concentration(5.0, ConcentrationUnit.mgPerML)));

      Map<String, Concentration> concentrations = <String, Concentration>{};
      concentrations.putIfAbsent(
          'a', () => Concentration(2.0, ConcentrationUnit.mgPerML));
      concentrations.putIfAbsent(
          'b', () => Concentration(1.0, ConcentrationUnit.mgPerML));

      Map<String, Dilutant> dilutants = <String, Dilutant>{};
      dilutants.putIfAbsent(
          'a',
              () => Dilutant(stockSolutions.values.elementAt(1),
              Concentration(1.0, ConcentrationUnit.mgPerML)));
      dilutants.putIfAbsent(
          'b',
              () => Dilutant(stockSolutions.values.elementAt(1),
              Concentration(1.0, ConcentrationUnit.mgPerML)));

      var dilution = Dilution(
          volume: Volume(100.0, VolumeUnits.ml),
          concentrations: concentrations,
          dilutants: dilutants);

      calculateDilutionFrom(dilution, stockSolutions);

      var volumes = dilution.dilutants.values.map((dil) => dil.volume.amount.roundToDouble()).toList();

      expect(volumes, [10.0, 20.0, 70.0]);
    });
  });

  test('simple dilution with 2 mutually exclusive solutions', () {
    var matrixA = RealMatrix.fromData(rows: 3, columns: 3, data: [
      // columns correspond to:
      // sol a, sol b, water
      [10.0, 0.0, 0.0], // Row 0 solution  a solute concentration
      [0.0, 5.0, 0.0], // Row 1. solution b solute concentrations
      [1.0, 1.0, 1.0] // Row 2 water
    ]);

    var matrixB = RealMatrix.fromData(rows: 3, columns: 1, data: [
      [1.0 * 100], // desired a concentration times ending volume
      [1.0 * 100], // desired b concentration times ending volume
      [100.0] // desired ending volume
    ]);

    final solver = LUSolver(matrix: matrixA, knownValues: matrixB.flattenData);

    final List<double> solution = solver.solve();

    print(solution.toString());
    //                Va  , Vb  , Vw
    expect(solution, [10.0, 20.0, 70.0]);
  });

  test('step dilution with a staying constant', () {
    var matrixA = RealMatrix.fromData(rows: 4, columns: 4, data: [
      // columns correspond to: sol a, sol b, dilution b, water
      // rows correspond to solutes
      [10.0, 0.0, 1.0, 0.0], // Row 0 solute a
      [0.0, 5.0, 1.0, 0.0], // Row 1 solute b
      [0.0, 0.0, 2.0, 0.0], // Row 1
      [1.0, 1.0, 1.0, 1.0] // Row 2
    ]);

    var matrixB = RealMatrix.fromData(rows: 4, columns: 1, data: [
      [1.0 * 100], // Row 1
      [0.1 * 100],
      [0.2 * 100],
      [100.0]
    ]);

    // Compute A^T * A (2x2)

    print("matrixA");
    print(matrixA);

    print("solve");
    final solver = LUSolver(matrix: matrixA, knownValues: matrixB.flattenData);

    final List<double> solution = solver.solve();

    print(solution.toString());

    expect(solution, [9.0, 0.0, 10.0, 81.0]);
  });

  test('step dilution check', () {
    var matrixA = RealMatrix.fromData(rows: 4, columns: 4, data: [
      // columns correspond to: sol a, sol b, dilution b, water
      // rows correspond to solutes
      [10.0, 0.0, 1.0, 0.0], // Row 0 solute a
      [0.0, 5.0, 1.0, 0.0], // Row 1 solute b
      [0.0, 0.0, 2.0, 0.0], // Row 2 contribution of both a and b
      [1.0, 1.0, 1.0, 1.0] // Row 3
    ]);

    var matrixB = RealMatrix.fromData(rows: 4, columns: 1, data: [
      [0.1 * 100],
      // The concentration of a in dilution d_0 should be 1/10 in d_1
      [0.5 * 100],
      // The concentration of b in dilution d_0 should be 1/2 in d_1
      [0.2 * 100],
      // Not sure of its meaning but it should be a and b together contributed to the solution
      [100.0]
    ]);

    // Compute A^T * A (2x2)

    print("matrixA");
    print(matrixA);

    print("solve");
    final solver = LUSolver(matrix: matrixA, knownValues: matrixB.flattenData);
    final List<double> solution = solver.solve();
    final solReal = RealMatrix.fromData(rows: 1, columns: 4, data: [solution]);
    print(solReal.transpose().toString());

    //Expected Volumes:
    //              [Vol. a, Vol. b, Vol. d_0,  Vol Water]
    expect(solution, [0.0, 8.0, 10.0, 82.0]);
  });

  test('step dilution another variation', () {
    var matrixA = RealMatrix.fromData(rows: 4, columns: 4, data: [
      // columns correspond to: sol a, sol b, dilution b, water
      // rows correspond to solutes
      [10.0, 0.0, 2.0, 0.0], // Row 0 solute a
      [0.0, 5.0, 1.0, 0.0], // Row 1 solute b
      [0.0, 0.0, 3.0, 0.0], // Row 2 contribution of both a and b
      [1.0, 1.0, 1.0, 1.0] // Row 3
    ]);

    var matrixB = RealMatrix.fromData(rows: 4, columns: 1, data: [
      [0.5 * 100],
      // The concentration of a in dilution d_0 should be 1/2 in d_1
      [0.1 * 100],
      // The concentration of b in dilution d_0 should be 1/10 in d_1
      [0.3 * 100],
      // Not sure of its meaning but it should be a and b together contributed to the solution
      [100.0]
    ]);

    // Compute A^T * A (2x2)

    print("matrixA");
    print(matrixA);
    print("solve");
    final solver = LUSolver(matrix: matrixA, knownValues: matrixB.flattenData);
    final List<double> solution = solver.solve();
    final solReal = RealMatrix.fromData(rows: 1, columns: 4, data: [solution]);
    print(solReal.transpose().toString());

    //Expected Volumes:
    //              [Vol. a, Vol. b, Vol. d_0,  Vol Water]
    expect(solution, [3.0, 0.0, 10.0, 87.0]);
  });

  test('with domain objects', () {
    var matrixA = RealMatrix.fromData(rows: 4, columns: 4, data: [
      // columns correspond to: sol a, sol b, dilution b, water
      // rows correspond to solutes
      [10.0, 0.0, 2.0, 0.0], // Row 0 solute a
      [0.0, 5.0, 1.0, 0.0], // Row 1 solute b
      [0.0, 0.0, 3.0, 0.0], // Row 2 contribution of both a and b
      [1.0, 1.0, 1.0, 1.0] // Row 3
    ]);

    var matrixB = RealMatrix.fromData(rows: 4, columns: 1, data: [
      [0.5 * 100],
      // The concentration of a in dilution d_0 should be 1/2 in d_1
      [0.1 * 100],
      // The concentration of b in dilution d_0 should be 1/10 in d_1
      [0.3 * 100],
      // Not sure of its meaning but it should be a and b together contributed to the solution
      [100.0]
    ]);

    // Compute A^T * A (2x2)

    print("matrixA");
    print(matrixA);
    print("solve");
    final solver = LUSolver(matrix: matrixA, knownValues: matrixB.flattenData);
    final List<double> solution = solver.solve();
    final solReal = RealMatrix.fromData(rows: 1, columns: 4, data: [solution]);
    print(solReal.transpose().toString());

    //Expected Volumes:
    //              [Vol. a, Vol. b, Vol. d_0,  Vol Water]
    expect(solution, [3.0, 0.0, 10.0, 87.0]);
  });
}

import 'package:equations/equations.dart';

const String WATER = 'H\u20820';
final Solution STOCK_WATER =
    Solution(WATER, Concentration(0.0, ConcentrationUnit.mgPerML));

bool containsNumber(String input) {
  final RegExp regex = RegExp(r'\d+(\.\d+)?');
  return regex.hasMatch(input);
}

enum ConcentrationUnit {
  mgPerML("mg/mL", 1e-3 / 1e-3),
  ugPerML("ug/mL", 1e-6 / 1e-3),
  ngPerML("ng/mL", 1e-9 / 1e-3);

  final String displayName;
  final double multiplier;

  const ConcentrationUnit(this.displayName, this.multiplier);
}

class Concentration {
  double amount;
  ConcentrationUnit unit;

  Concentration(this.amount, this.unit);

  Concentration copy() {
    return Concentration(amount, unit);
  }

  @override
  String toString() {
    var units = unit.displayName;
    return '$amount $units';
  }
}

enum VolumeUnits {
  l("L", 1),
  ml("mL", 1e-3),
  ul("uL", 1e-6),
  nl("nL", 1e-9);

  final String displayName;
  final double multiplier;

  const VolumeUnits(this.displayName, this.multiplier);
}

class Volume {
  double amount = 0.0;
  VolumeUnits units = VolumeUnits.ml;

  Volume(this.amount, this.units);

  Volume copy() => Volume(amount, units);

  @override
  String toString() {
    var displayName = units.displayName;
    var amountRounded = amount.toStringAsFixed(1);
    return '$amountRounded $displayName';
  }
}

class Solution {
  final String name;
  final Concentration concentration;

  Solution(final this.name, final this.concentration);

  Solution copy() {
    return Solution(name, concentration.copy());
  }
}

class Dilutant {
  final Solution solution;
  late Volume volume = Volume(0.0, VolumeUnits.ml);
  Concentration concentration;

  Dilutant(this.solution, this.concentration);

  Dilutant.n(this.solution, this.concentration, this.volume);

  Dilutant copy() {
    return Dilutant.n(solution.copy(), concentration.copy(), volume.copy());
  }
}

enum DilutionType { SIMPLE, SERIAL }

class Dilution {
  DilutionType dilutionType;
  Volume volume;
  Map<String, Concentration> concentrations;
  Map<String, Dilutant> dilutants;

  Dilution(
      {required this.volume,
      required this.concentrations,
      required this.dilutants,
      this.dilutionType = DilutionType.SIMPLE});

  Dilution copy() => Dilution(
      volume: volume.copy(),
      concentrations: concentrations.map((k, v) => MapEntry(k, v.copy())),
      dilutants: dilutants.map((k, v) => MapEntry(k, v.copy())));

  Dilution compact(String name, Volume volume) {
    Dilution dilution = Dilution(
        volume: volume,
        concentrations: concentrations.map((k, v) => MapEntry(k, v.copy())),
        dilutants: dilutants.map((k, v) => MapEntry(k, v.copy())));
    return dilution;
  }
}

/// Extract stock solution concentrations into list which will be used
/// as diagonal for system of linear equations
List<double> extractStockConcentrations(Map<String, Solution> solutions) {
  List<double> stockConcentrations = [];
  solutions.entries.forEach((stock) => {
        if (stock.key.compareTo(WATER) != 0)
          {
            stockConcentrations.add(stock.value.concentration.amount *
                stock.value.concentration.unit.multiplier)
          }
      });
  //add Water add end
  stockConcentrations.add(1.0);
  return stockConcentrations;
}

List<double> extractDilutionConcentrations(Dilution dilution) {
  List<double> dilutionConcentrations = [];
  double totalVolumeCalc =
      dilution.volume.amount * dilution.volume.units.multiplier;
  dilution.dilutants.entries.forEach((dilutant) => {
        if (dilutant.key.compareTo(WATER) != 0)
          {
            dilutionConcentrations.add(dilutant.value.concentration.amount *
                dilutant.value.concentration.unit.multiplier *
                totalVolumeCalc)
          }
      });
  //add Water add end
  dilutionConcentrations.add(totalVolumeCalc);
  return dilutionConcentrations;
}

/// Create a NxN matrix with a bottom row of ones and using diagonalValues
List<List<double>> createStockMatrix(List<double> diagonalValues) {
  int N = diagonalValues.length;
  return List.generate(
      N,
      (i) => List.generate(
          N,
          (j) => (i == N - 1)
              ? 1
              : (i == j)
                  ? diagonalValues[i]
                  : 0.0));
}

List<double> solveItTranspose(
    List<List<double>> matrixAa, List<List<double>> matrixBb) {
  final matrixA = RealMatrix.fromData(
      rows: matrixAa.length, columns: matrixAa.length, data: matrixAa);

  final matrixB = RealMatrix.fromData(
      rows: matrixBb.first.length, columns: 1, data: matrixBb);

  // Compute A^T * A (2x2)
  print(matrixA);
  final at = matrixA.transpose();
  print(at);
  final atA = at * matrixA;
  print(atA);

  final atB = matrixA.transpose() * matrixB;

  final solver = LUSolver(
      matrix:
          RealMatrix.fromData(rows: 2, columns: 2, data: atA.toListOfList()),
      knownValues: atB.flattenData);

  final List<double> solution = solver.solve();

  print(solution.toString());

  return solution;
}

List<double> solveIt(List<List<double>> matrixAa, List<List<double>> matrixBb) {
  final matrixA = RealMatrix.fromData(
      rows: matrixAa.length, columns: matrixAa.length, data: matrixAa);

  final matrixB = RealMatrix.fromData(
      rows: matrixBb.first.length, columns: 1, data: matrixBb);

  final solver = LUSolver(matrix: matrixA, knownValues: matrixB.flattenData);
  final List<double> solution = solver.solve();
  return solution;
}

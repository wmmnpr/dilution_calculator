import 'dart:math';
import 'package:dart_numerics/dart_numerics.dart';
import 'package:equations/equations.dart';

const String WATER = 'H\u20820';

enum ConcentrationUnit {
  mgPerML("mg/mL", 1e-3 / 1e-3),
  ugPerML("ug/mL", 1e-6 / 1e-3),
  ngPerML("ng/mL", 1e-9 / 1e-3);

  final String displayName;
  final double multiplier;

  const ConcentrationUnit(this.displayName, this.multiplier);
}

class Concentration {
  final double amount;
  final ConcentrationUnit unit;

  Concentration(this.amount, this.unit);

  @override
  String toString() {
    var units = unit.displayName;
    return '$amount $units';
  }
}


enum VolumeUnits {
  l("L", 1),
  ml("mL", 1e-3),
  ul("uL", 1e-9);

  final String displayName;
  final double multiplier;

  const VolumeUnits(this.displayName, this.multiplier);
}

class Volume {
  double amount = 0.0;
  VolumeUnits units = VolumeUnits.ml;

  Volume(this.amount, this.units);

  @override
  String toString() {
    var displayName = units.displayName;
    return '$amount $displayName';
  }
}

class Solution {
  final String name;
  final Concentration concentration;

  Solution(this.name, this.concentration);
}

class Dilutant {
  final Solution solution;
  late Volume volume = Volume(0.0, VolumeUnits.ml);
  Concentration concentration;

  Dilutant(this.solution, this.concentration);
}

class Dilution {
  final Volume volume;
  final Map<String, Concentration> concentrations;
  final Map<String, Dilutant> dilutants;

  Dilution(this.volume, this.concentrations, this.dilutants);
}

/// Extract stock solution concentrations into list which will be used
/// as diagonal for system of linear equations
List<double> extractStockConcentrations(Map<String, Solution>solutions){
  List<double> stockConcentrations = [];
  solutions.entries.forEach((stock)=>{
    if(stock.key.compareTo(WATER) != 0){
      stockConcentrations.add(stock.value.concentration.amount * stock.value.concentration.unit.multiplier)
    }
  });
  //add Water add end
  stockConcentrations.add(1.0);
  return stockConcentrations;
}

List<double>extractDilutionConcentrations(Dilution dilution){
  List<double> dilutionConcentrations = [];
  double totalVolumeCalc = dilution.volume.amount * dilution.volume.units.multiplier;
  dilution.dilutants.entries.forEach((dilutant)=>{
    if(dilutant.key.compareTo(WATER) != 0){
      dilutionConcentrations.add(dilutant.value.concentration.amount * dilutant.value.concentration.unit.multiplier * totalVolumeCalc)
    }
  });
  //add Water add end
  dilutionConcentrations.add(totalVolumeCalc);
  return dilutionConcentrations;
}

/// Create a NxN matrix with a bottom row of ones and using diagonalValues
List<List<double>> createStockMatrix(List<double> diagonalValues) {
  int N = diagonalValues.length;
  return List.generate(N, (i) =>
      List.generate(N, (j) =>
      (i == N - 1) ? 1 : (i == j) ? diagonalValues[i] : 0.0
      )
  );
}


List<double> solveItTranspose(List<List<double>>matrixAa, List<List<double>>matrixBb){
  final matrixA = RealMatrix.fromData(
    rows: matrixAa.length,
    columns: matrixAa.length,
    data: matrixAa
  );

  final matrixB = RealMatrix.fromData(
    rows: matrixBb.first.length,
    columns: 1,
    data: matrixBb
  );

  // Compute A^T * A (2x2)
  print(matrixA);
  final at = matrixA.transpose();
  print(at);
  final atA = at * matrixA;
  print(atA);

  final atB = matrixA.transpose() * matrixB;

  final solver = LUSolver(matrix: RealMatrix.fromData(rows: 2, columns: 2, data: atA.toListOfList()), knownValues: atB.flattenData);

  final List<double>solution = solver.solve();

  print(solution.toString());

  return solution;
}

List<double> solveIt(List<List<double>>matrixAa, List<List<double>>matrixBb){
  final matrixA = RealMatrix.fromData(
      rows: matrixAa.length,
      columns: matrixAa.length,
      data: matrixAa
  );

  final matrixB = RealMatrix.fromData(
      rows: matrixBb.first.length,
      columns: 1,
      data: matrixBb
  );

  final solver = LUSolver(matrix: matrixA, knownValues: matrixB.flattenData);
  final List<double>solution = solver.solve();
  return solution;
}

List<double>? computeMixtureVolumes(double Vm, List<List<double>> stockConcentrations, List<double> finalConcentrations) {
  int numStocks = stockConcentrations.length;
  int numComponents = stockConcentrations[0].length;

  // Construct coefficient matrix A
  List<List<double>> A = List.generate(numComponents + 1, (i) => List.filled(numStocks, 0.0));

  // First row ensures total volume constraint
  for (int j = 0; j < numStocks; j++) {
    A[0][j] = 1;
  }

  // Remaining rows for mass balance of each component
  for (int i = 0; i < numComponents; i++) {
    for (int j = 0; j < numStocks; j++) {
      A[i + 1][j] = stockConcentrations[j][i];
    }
  }

  // Construct right-hand side vector B
  List<double> B = [Vm, ...finalConcentrations.map((c) => c * Vm)];

  // Solve Ax = B using least squares method
  List<double>? volumes = solveLinearSystem(A, B);

  // Ensure non-negative values
  if (volumes == null || volumes.any((v) => v < 0)) return null;

  return volumes;
}

List<double>? solveLinearSystem(List<List<double>> A, List<double> B) {
  int n = A.length;
  List<List<double>> matrix = List.generate(n, (i) => List.from(A[i]));
  List<double> rhs = List.from(B);

  // Perform Gaussian Elimination with Partial Pivoting
  for (int i = 0; i < n; i++) {
    // Find pivot row
    int pivot = i;
    for (int j = i + 1; j < n; j++) {
      if (matrix[j][i].abs() > matrix[pivot][i].abs()) {
        pivot = j;
      }
    }

    if (matrix[pivot][i].abs() < 1e-10) {
      return null; // Singular matrix, no unique solution
    }

    // Swap rows
    List<double> tempRow = matrix[i];
    matrix[i] = matrix[pivot];
    matrix[pivot] = tempRow;

    double tempVal = rhs[i];
    rhs[i] = rhs[pivot];
    rhs[pivot] = tempVal;

    // Normalize pivot row
    double pivotValue = matrix[i][i];
    for (int j = i; j < n; j++) {
      matrix[i][j] /= pivotValue;
    }
    rhs[i] /= pivotValue;

    // Eliminate below
    for (int j = i + 1; j < n; j++) {
      double factor = matrix[j][i];
      for (int k = i; k < n; k++) {
        matrix[j][k] -= factor * matrix[i][k];
      }
      rhs[j] -= factor * rhs[i];
    }
  }

  // Back-substitution
  List<double> solution = List.filled(n, 0.0);
  for (int i = n - 1; i >= 0; i--) {
    solution[i] = rhs[i];
    for (int j = i + 1; j < n; j++) {
      solution[i] -= matrix[i][j] * solution[j];
    }
  }

  return solution;
}


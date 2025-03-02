import 'dart:math';
import 'package:dart_numerics/dart_numerics.dart';

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

void main() {
  double Vm = 100; // Total final volume in mL
  List<List<double>> stockConcentrations = [
    [100, 0], // Stock 1 (mg/mL for each component)
    [0, 100], // Stock 2
    [0, 0]   // Stock 3 (optional additional stock)
  ];
  List<double> finalConcentrations = [10, 10]; // Desired final concentrations

  List<double>? volumes = computeMixtureVolumes(Vm, stockConcentrations, finalConcentrations);
  if (volumes != null) {
    for (int i = 0; i < volumes.length; i++) {
      print("Use ${volumes[i].toStringAsFixed(2)} mL of Stock ${i + 1}");
    }
  } else {
    print("No valid solution: check concentrations and target values.");
  }
}

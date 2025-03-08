import 'package:equations/equations.dart';


void solveIt(){
  // Define the coefficient matrix (A)



  // Define matrix A (3x2)
  final matrixA = RealMatrix.fromData(
    rows: 2,
    columns: 2,
    data: [
      [16.0, 0.0],
      [1.0, 1.0]
    ],
  );

  final matrixB = RealMatrix.fromData(
    rows: 2,
    columns: 1,
    data: [
      [0.5 * 8.0],
      [8.0]
    ],
  );

  // Compute A^T * A (2x2)
  print(matrixA);
  final at = matrixA.transpose();
  print(at);
  final atA = at * matrixA;
  print(atA);

  final atB = matrixA.transpose() * matrixB;

  final solver = LUSolver(matrix: RealMatrix.fromData(rows: 2, columns: 2, data: atA.toListOfList()), knownValues: atB.flattenData);

  final solution = solver.solve();

  print(solution.toString());

  print("done");
}
void main() {

  solveIt();

}



import 'package:flutter/material.dart';

class DiluteByInputDialog extends StatefulWidget {
  @override
  _DiluteByInputDialogState createState() => _DiluteByInputDialogState();
}

class _DiluteByInputDialogState extends State<DiluteByInputDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _errorMessage;

  void _submit() {
    double? value = double.tryParse(_controller.text);
    if (value == null) {
      setState(() {
        _errorMessage = "Please enter a valid number";
      });
      return;
    }

    Navigator.of(context).pop(value); // Return the entered double
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Dilute by factor"),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: "Number",
          errorText: _errorMessage,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          // Close without returning
          child: Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text("OK"),
        ),
      ],
    );
  }
}

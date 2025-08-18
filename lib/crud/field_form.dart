import 'package:flutter/material.dart';

class FieldForm extends StatelessWidget {
  String label;
  bool isPassword;
  TextEditingController controller;
  
    FieldForm({
    required this.label,
    required this.isPassword,
    required this.controller,
    super.key});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
        obscureText: isPassword,
        controller: controller,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          labelText: label,
          labelStyle: const TextStyle(
            color: Colors.black,
            fontSize: 16,
          ),

        ),
    );
  }
}
import 'package:flutter/material.dart';
import 'field_form.dart';

class UserForm extends StatefulWidget {
  const UserForm({super.key});

  @override
  State <UserForm> createState() =>  UserFormState();
}

class UserFormState extends State <UserForm> {
  TextEditingController controllerName = TextEditingController();
  TextEditingController controllerEmail = TextEditingController();
  TextEditingController controllerSenha = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          FieldForm(
            label: 'Name',
            isPassword: false,
            controller: controllerName,
          ),
          FieldForm(
            label: 'Email',
            isPassword: false,
            controller: controllerEmail,
          ),
          FieldForm(
            label: 'Senha',
            isPassword: true,
            controller: controllerSenha,
          ),
          SizedBox(
            width: double.infinity,

            child: TextButton(
              onPressed: () {
                // Handle form submission
                print('Name: ${controllerName.text}');
                print('Email: ${controllerEmail.text}');
                print('Senha: ${controllerSenha.text}');
              },
              child: const Text('Salvar'),
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.blue),
                foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
              ),
            ),
          ),
        ],
      )
    );
  }
}
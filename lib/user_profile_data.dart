import 'package:flutter/material.dart';

class UserProfileData extends ChangeNotifier {
  UserProfileData()
      : name = 'João da Silva',
        email = 'joao.silva@exemplo.com',
        phone = '123-456-7890',
        userType = 1, // Adicionando o tipo de usuário
        monthlyPayments = {
          'Jan': false,
          'Fev': false,
          'Mar': false,
          'Abr': false,
          'Mai': false,
          'Jun': false,
          'Jul': false,
          'Ago': false,
          'Set': false,
          'Out': false,
          'Nov': false,
          'Dez': false,
        };

  String name;
  String email;
  String phone;
  int userType; // Adicionando o campo userType
  Map<String, bool> monthlyPayments;

  void updateName(String newName) {
    name = newName;
    notifyListeners();
  }

  void updateUserType(int newType) {
    userType = newType;
    notifyListeners();
  }

  void updateEmail(String newEmail) {
    email = newEmail;
    notifyListeners();
  }

  void updatePhone(String newPhone) {
    phone = newPhone;
    notifyListeners();
  }

  void togglePayment(String month, bool? newValue) {
    if (newValue != null) {
      monthlyPayments[month] = newValue;
      notifyListeners();
    }
  }
}

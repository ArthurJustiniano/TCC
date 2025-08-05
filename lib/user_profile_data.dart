import 'package:flutter/material.dart';

class UserProfileData extends ChangeNotifier {
  UserProfileData()
      : name = 'João da Silva',
        email = 'joao.silva@exemplo.com',
        phone = '123-456-7890',
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
  Map<String, bool> monthlyPayments;

  void togglePayment(String month, bool? newValue) {
    if (newValue != null) {
      monthlyPayments[month] = newValue;
      notifyListeners();
    }
  }
}

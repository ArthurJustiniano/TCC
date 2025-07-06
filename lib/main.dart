import 'package:flutter/material.dart';

main(){
  runApp(new PerguntaApp());
}
@override
class PerguntaApp extends StatelessWidget{

    void responder() {
      print('Resposta selecionada!');
    }

    Widget build(BuildContext context){
      final List<String> perguntas = [
        'Qual é a sua cor favorita?',
        'Qual é o seu animal favorito?',
        'Qual é o seu esporte favorito?',
      ];

      return MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: Text('Perguntas'),
          ),
          body: Column(
            children: <Widget>[
              Text(perguntas[0]),
              ElevatedButton(
                child: Text('Resposta 1'),
                onPressed: responder,
              )
            ]
          ),
        ),
      );
    }
}

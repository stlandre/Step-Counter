import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:steps/model/itemstep.dart';
import 'package:steps/model/steps.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import 'package:motion_sensors/motion_sensors.dart';
import 'package:steps/main.dart';

class Settings extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return SettingsState();
  }
}

class SettingsState extends State<Settings> {
  int _groupValue = 3;
  double _parametroPeriodo = 15.0;
  double _parametroAceleracaoUserzMax = 0.6;

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text('Configurações'),
      ),
      body: Material(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Frequência sensor'),
            Container(
              padding: const EdgeInsets.all(8.0),
              height: MediaQuery.of(context).size.height/3, //talvez haja uma maneira melhor de fazer isso. Talvez apresente problema ao rotacionar a tela
              width: MediaQuery.of(context).size.width,
              child: Center(
                child:
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Radio(
                        value: 1,
                        groupValue: _groupValue,
                        onChanged: (dynamic value){ }, /*=> setUpdateInterval(
                      value, Duration.microsecondsPerSecond ~/ 1),*/
                      ),
                      Text("1 FPS"),
                      Radio(
                        value: 2,
                        groupValue: _groupValue,
                        onChanged: (dynamic value){ }, /*=> setUpdateInterval(
                      value, Duration.microsecondsPerSecond ~/ 30),*/
                      ),
                      Text("30 FPS"),
                      Radio(
                        value: 3,
                        groupValue: _groupValue,
                        onChanged: (dynamic value){ }, /*=> setUpdateInterval(
                      value, Duration.microsecondsPerSecond ~/ 60),*/
                      ),
                      Text("60 FPS"),
                    ],
                  ),
              ),
            ),

          ],
        ),

      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          //_criaParametros(context);
        },
        child: Icon(Icons.save),
      ),
    );
  }

  /*void _criaParametros(BuildContext context) {
    //final Step parametroCriado = Step(15.0, 0.6);
    if(_passos.length > 5) {
      int indice = 0;
      List<Steps> pss = [];
      double media = 0.0;
      _passos.sort((a, b) => a.aceleracaoMax.compareTo(b.aceleracaoMax));

      while(indice < _passos.length){
        if(_passos[indice].aceleracaoMax/ _passos.last.aceleracaoMax >= 0.75){
          pss.add(_passos[indice]);
        }
        indice++;
      }

      indice = 0;

      while(indice < pss.length){
        media = pss[indice].periodo + media;
        indice++;
      }

      media = media / pss.length;

      final Steps parametroCriado = Steps(media, pss.first.aceleracaoMax);
      Navigator.pop(context, parametroCriado);
    }

  }*/
}
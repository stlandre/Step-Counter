import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:steps/model/itemstep.dart';
import 'package:steps/model/steps.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import 'package:motion_sensors/motion_sensors.dart';
import 'package:steps/main.dart';

class AnaliseSteps extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return AnaliseStepsState();
  }
}

class AnaliseStepsState extends State<AnaliseSteps> {
  final List<Steps> _passos = [];

  Vector3 _accelerometer = Vector3.zero();
  Vector3 _magnetometer = Vector3.zero();
  Vector3 _userAaccelerometer = Vector3.zero();

  Vector3 _aceleracao = Vector3.zero();
  Vector3 _aceleracaoUser = Vector3.zero();
  Matrix3 _mudancaBase = Matrix3.identity();

  double _aceleracaoUserz = 0.0;
  double _periodo = 0.0;
  //bool _entrada = false;
  double _aceleracaoUserzMax = 0.0;

  int _contador = 1;

  @override
  void initState() {
    super.initState();

    motionSensors.accelerometerUpdateInterval = Duration.microsecondsPerSecond ~/ 60;
    motionSensors.userAccelerometerUpdateInterval = Duration.microsecondsPerSecond ~/ 60;
    motionSensors.magnetometerUpdateInterval = Duration.microsecondsPerSecond ~/ 60;

    motionSensors.accelerometer.listen((AccelerometerEvent event) {
      setState(() {
        _accelerometer.setValues(event.x, event.y, event.z);
      });
    });
    motionSensors.userAccelerometer.listen((UserAccelerometerEvent event) {
      setState(() {
        _userAaccelerometer.setValues(event.x, event.y, event.z);
      });
    });
    motionSensors.magnetometer.listen((MagnetometerEvent event) {
      setState(() {
        _magnetometer.setValues(event.x, event.y, event.z);
        var matrix =
        motionSensors.getRotationMatrix(_accelerometer, _magnetometer);

        //data Processing.
        final Vector3 linha0 = Vector3(
            matrix.getRow(0).x.toPrecision(2),
            matrix.getRow(0).y.toPrecision(2),
            matrix.getRow(0).z.toPrecision(2)); //matrix.getRow(0).xyz;
        final Vector3 linha1 = Vector3(
            matrix.getRow(1).x.toPrecision(2),
            matrix.getRow(1).y.toPrecision(2),
            matrix.getRow(1).z.toPrecision(2)); //matrix.getRow(1).xyz;
        final Vector3 linha2 = Vector3(
            matrix.getRow(2).x.toPrecision(2),
            matrix.getRow(2).y.toPrecision(2),
            matrix.getRow(2).z.toPrecision(2)); //matrix.getRow(2).xyz;
        _mudancaBase.setRow(0, linha0);
        _mudancaBase.setRow(1, linha1);
        _mudancaBase.setRow(2, linha2);

        _aceleracaoUser = Vector3(
            _userAaccelerometer.x.toPrecision(2),
            _userAaccelerometer.y.toPrecision(2),
            _userAaccelerometer.z.toPrecision(2));

        if (_aceleracaoUser.y.abs() <= 0.3) {
          _aceleracaoUser = Vector3.zero();
          //_velocidadeF = Vector3.zero();
        } else {
          if (_aceleracaoUser.distanceTo(Vector3.zero()) <= 0.5) {
            _aceleracaoUser = Vector3.zero();
            //_velocidadeF = Vector3.zero();
          }
        }

        //model(); //contagem dos passos e coordenadas no plano xy.

        //step Count.
        _aceleracaoUserz = (_mudancaBase * _aceleracaoUser).z;

        if (_aceleracaoUserz > 0.0) {
          _periodo++; //conta o tempo em que a aceleracaoUserz permanece positiva
          if (_aceleracaoUserzMax < _aceleracaoUserz) {
            _aceleracaoUserzMax = _aceleracaoUserz;
          }
        } else {
          if (_aceleracaoUserzMax >= 0.5) {
            //_passos++;
            final Steps passo = Steps(_periodo, _aceleracaoUserzMax);
            _passos.add(passo);
          }
          _periodo = 0;
          _aceleracaoUserzMax = 0.0;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text('Análise'),
      ),
      body: ListView.builder(
        itemCount: _passos.length,
        itemBuilder: (context, indice) {
          return ItemStep(_passos[indice]);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _criaParametros(context);
        },
        child: Icon(Icons.show_chart_sharp),
      ),
    );
  }

  void _criaParametros(BuildContext context) {
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

  }
}
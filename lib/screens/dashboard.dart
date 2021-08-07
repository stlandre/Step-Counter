import 'package:flutter/cupertino.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import 'package:motion_sensors/motion_sensors.dart';
import 'package:steps/main.dart';

import 'analisesteps.dart';

class Dashboard extends StatefulWidget {
  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  //dados dos sensores
  Vector3 _accelerometer = Vector3.zero();
  Vector3 _magnetometer = Vector3.zero();
  Vector3 _userAaccelerometer = Vector3.zero();

  int? _groupValue = 3;

  //dados do modelo Físico elaborado
  Vector3 _aceleracao = Vector3.zero();
  Vector3 _aceleracaoUser = Vector3.zero();
  Vector3 _velocidade0 = Vector3.zero();
  Vector3 _posicao0 = Vector3.zero();
  Vector3 _velocidadeF = Vector3.zero();
  Vector3 _posicaoF = Vector3.zero();
  double _deltaT = 1.0 / 100.0;
  Matrix3 _mudancaBase = Matrix3.identity();
  Vector3 _yBase = Vector3.zero();

  double _aceleracaoUserz = 0.0;
  double _periodo = 0.0;
  bool _entrada = false;
  double _aceleracaoUserzMax = 0.0;

  double _parametroPeriodo = 15.0;
  double _parametroAceleracaoUserzMax = 0.6;

  int _passos = 0;

  int _contador = 1;

  void dataProcessing(Matrix4 matrix) {
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
      _velocidadeF = Vector3.zero();
    } else {
      if (_aceleracaoUser.distanceTo(Vector3.zero()) <= 0.5) {
        _aceleracaoUser = Vector3.zero();
        _velocidadeF = Vector3.zero();
      }
    }
  }

  void stepCount() {
    _aceleracaoUserz = (_mudancaBase * _aceleracaoUser).z; //aceleraçao Z do usuario no referencial absoluto

    if (_aceleracaoUserz > 0.0) {
      _periodo++; //conta o periodo em que a aceleracaoUserz permanece positiva
      if (_aceleracaoUserzMax < _aceleracaoUserz) {
        _aceleracaoUserzMax = _aceleracaoUserz;
      }
    } else {
      _periodo = 0;
      _aceleracaoUserzMax = 0.0;
      _entrada = false;
    }

    if (_periodo >= _parametroPeriodo &&
        _entrada == false &&
        _aceleracaoUserzMax >= _parametroAceleracaoUserzMax) {
      _passos++;
      _entrada = true;
    }
  }

  void coordinatesInThePlan() {
    _aceleracaoUser = Vector3(
        0.0,
        _aceleracaoUser.distanceTo(Vector3.zero()),
        0.0); //Colocando modulo de _aceleracaoUser na componente y de _aceleracaoUser

    _aceleracao = _mudancaBase * _aceleracaoUser; //vetor aceleraçao do usuario no referencial absoluto

    _yBase = _mudancaBase * Vector3(0.0, 1.0, 0.0); //variavel criada somente para alguns testes

    _aceleracao = Vector3(_aceleracao.x, _aceleracao.y, 0.0); //projeçao do vetor _aceleracao no plano xy

    _velocidade0 = _velocidadeF;
    _posicao0 = _posicaoF;
    _velocidadeF = _velocidade0 + (_aceleracao * _deltaT);
    _posicaoF = _posicao0 +
        _velocidade0 * _deltaT +
        _aceleracao * (_deltaT * _deltaT) / 2.0;
  }

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

        //data Processing. -----------------------
        dataProcessing(matrix);
/*        final Vector3 linha0 = Vector3(
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
          _velocidadeF = Vector3.zero();
        } else {
          if (_aceleracaoUser.distanceTo(Vector3.zero()) <= 0.5) {
            _aceleracaoUser = Vector3.zero();
            _velocidadeF = Vector3.zero();
          }
        }*/

        //model(); //contagem dos passos e coordenadas no plano xy.

        //step Count. --------------------------
        stepCount();
/*        _aceleracaoUserz = (_mudancaBase * _aceleracaoUser).z; //aceleraçao Z do usuario no referencial absoluto

        if (_aceleracaoUserz > 0.0) {
          _periodo++; //conta o periodo em que a aceleracaoUserz permanece positiva
          if (_aceleracaoUserzMax < _aceleracaoUserz) {
            _aceleracaoUserzMax = _aceleracaoUserz;
          }
        } else {
          _periodo = 0;
          _aceleracaoUserzMax = 0.0;
          _entrada = false;
        }

        if (_periodo >= _parametroPeriodo &&
            _entrada == false &&
            _aceleracaoUserzMax >= _parametroAceleracaoUserzMax) {
          _passos++;
          _entrada = true;
        }*/

        //coordinates In The Plan. --------------------------
        coordinatesInThePlan();
/*        _aceleracaoUser = Vector3(
            0.0,
            _aceleracaoUser.distanceTo(Vector3.zero()),
            0.0); //Colocando modulo de _aceleracaoUser na componente y de _aceleracaoUser

        _aceleracao = _mudancaBase * _aceleracaoUser; //vetor aceleraçao do usuario no referencial absoluto

        _yBase = _mudancaBase * Vector3(0.0, 1.0, 0.0); //variavel criada somente para alguns testes

        _aceleracao = Vector3(_aceleracao.x, _aceleracao.y, 0.0); //projeçao do vetor _aceleracao no plano xy

        _velocidade0 = _velocidadeF;
        _posicao0 = _posicaoF;
        _velocidadeF = _velocidade0 + (_aceleracao * _deltaT);
        _posicaoF = _posicao0 +
            _velocidade0 * _deltaT +
            _aceleracao * (_deltaT * _deltaT) / 2.0;*/

        _contador++;
      });
    });
  }

  void setUpdateInterval(int? groupValue, int interval) {
    motionSensors.accelerometerUpdateInterval = interval;
    motionSensors.userAccelerometerUpdateInterval = interval;
    motionSensors.magnetometerUpdateInterval = interval;
    setState(() {
      _groupValue = groupValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    //setUpdateInterval(_groupValue, Duration.microsecondsPerSecond ~/ 60);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Steps'),
      ),
      body: Material(
        //color: Colors.grey[300],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(8.0),
              height: MediaQuery.of(context).size.height/3, //talvez haja uma maneira melhor de fazer isso. Talvez apresente problema ao rotacionar a tela
              width: MediaQuery.of(context).size.width,
              child: Center(
                child: Material(
                  color: Theme.of(context).accentColor,
                  borderRadius: BorderRadius.all(
                      Radius.circular(50)
                  ),
                  child: InkWell(
                    onTap: (){
                      _passos = 0;
                    },
                    child: Container(
                      child: Center(
                        child: Text(
                          '$_passos',
                          textScaleFactor: 3.0,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      height: 100,
                      width: 100,
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8.0),
              height: 150,
              width: MediaQuery.of(context).size.width,
              child: Row (
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Material(
                        color: Theme.of(context).accentColor,
                        child: InkWell(
                          onTap: (){
                            final Future future = Navigator.push(context, MaterialPageRoute(builder: (context){
                              return AnaliseSteps();
                            }));
                            future.then((parametroRecebido){
                              setState(() {
                                if(parametroRecebido.periodo <= 50.0) {
                                  _parametroPeriodo = parametroRecebido.periodo;
                                }

                                if(parametroRecebido.aceleracaoMax <= 1.0) {
                                  _parametroAceleracaoUserzMax = parametroRecebido.aceleracaoMax * 0.6;
                                }
                              });
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.all(8.0),
                            height: 100,
                            width: 150,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Icon(
                                  Icons.show_chart,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                Text(
                                  'Analisar passo',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      )
                  ),
                  Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Material(
                        color: Theme.of(context).accentColor,
                        child: InkWell(
                          onTap: (){

                          },
                          child: Container(
                            padding: EdgeInsets.all(8.0),
                            height: 100,
                            width: 150,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Icon(
                                  Icons.settings,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                Text(
                                  'Configurações',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      )
                  ),
                ],
              ),
            ),


          ],
        ),
      ),
    );
  }
}

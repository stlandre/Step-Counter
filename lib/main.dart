import 'dart:math';

import 'package:flutter/material.dart';
import 'package:steps/screens/dashboard.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import 'package:motion_sensors/motion_sensors.dart';

void main() {
  runApp(StepsApp());
}

extension Precision on double {
  double toPrecision(int fractionDigits) {
    int mod = 10 ^ fractionDigits;
    return ((this * mod).round().toDouble() / mod);
  }
}

class StepsApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(
      home: Pedometro(),//Dashboard(),
    );
  }
}

class Pedometro extends StatefulWidget {
  @override
  _PedometroState createState() => _PedometroState();
}

class _PedometroState extends State<Pedometro> {
  Vector3 _accelerometer = Vector3.zero();
  Vector3 _magnetometer = Vector3.zero();
  Vector3 _userAaccelerometer = Vector3.zero();

  int? _groupValue = 3;

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
          _velocidadeF = Vector3.zero();
        } else {
          if (_aceleracaoUser.distanceTo(Vector3.zero()) <= 0.5) {
            _aceleracaoUser = Vector3.zero();
            _velocidadeF = Vector3.zero();
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

        //coordinates In The Plan.
        _aceleracaoUser = Vector3(
            0.0,
            _aceleracaoUser.distanceTo(Vector3.zero()),
            0.0); //Colocando modulo de _aceleracaoUser na componente y de _aceleracaoUser

        _aceleracao = _mudancaBase * _aceleracaoUser; //mudança de base

        _yBase = _mudancaBase * Vector3(0.0, 1.0, 0.0);

        _aceleracao = Vector3(_aceleracao.x, _aceleracao.y, 0.0);

        _velocidade0 = _velocidadeF;
        _posicao0 = _posicaoF;
        _velocidadeF = _velocidade0 + (_aceleracao * _deltaT);
        _posicaoF = _posicao0 +
            _velocidade0 * _deltaT +
            _aceleracao * (_deltaT * _deltaT) / 2.0;

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
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Contador'),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Text('$_contador'),
              ],
            ),
            Text('Update Interval'),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Radio(
                  value: 1,
                  groupValue: _groupValue,
                  onChanged: (dynamic value) => setUpdateInterval(
                      value, Duration.microsecondsPerSecond ~/ 1),
                ),
                Text("1 FPS"),
                Radio(
                  value: 2,
                  groupValue: _groupValue,
                  onChanged: (dynamic value) => setUpdateInterval(
                      value, Duration.microsecondsPerSecond ~/ 30),
                ),
                Text("30 FPS"),
                Radio(
                  value: 3,
                  groupValue: _groupValue,
                  onChanged: (dynamic value) => setUpdateInterval(
                      value, Duration.microsecondsPerSecond ~/ 60),
                ),
                Text("60 FPS"),
              ],
            ),

            Text('Período'),
            Slider(
              value: _parametroPeriodo,
              min: 0,
              max: 50,
              divisions: 50,
              label: _parametroPeriodo.toString(),
              onChanged: (double value) {
                setState(() {
                  _parametroPeriodo = value;
                });
              },
            ),
            Text('Força mínima de um passo'),
            Slider(
              value: _parametroAceleracaoUserzMax,
              min: 0,
              max: 4,
              divisions: 40,
              label: _parametroAceleracaoUserzMax.toString(),
              onChanged: (double value) {
                setState(() {
                  _parametroAceleracaoUserzMax = value;
                });
              },
            ),
            Text(
              'Passos',
              textScaleFactor: 2.0,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Text(
                  '$_passos',
                  textScaleFactor: 3.0,
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () {
                _passos = 0;
              },
              child: Text('Zerar Passos'),
            ),
            ElevatedButton(
              onPressed: () {
                _passos = 0;
                _parametroAceleracaoUserzMax = 0.6;
                _parametroPeriodo = 15.0;
              },
              child: Text('Reset'),
            ),
            ElevatedButton(
                onPressed: (){
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
                child: Text('Analisar Passo')),
          ],
        ),
      ),
    );
  }
}

class Step {
  final double periodo;
  final double aceleracaoMax;

  Step(this.periodo, this.aceleracaoMax);
}

class AnaliseSteps extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return AnaliseStepsState();
  }
}

class AnaliseStepsState extends State<AnaliseSteps> {
  final List<Step> _passos = [];

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
            final Step passo = Step(_periodo, _aceleracaoUserzMax);
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
      List<Step> pss = [];
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

      final Step parametroCriado = Step(media, pss.first.aceleracaoMax);
      Navigator.pop(context, parametroCriado);
    }

  }
}

class ItemStep extends StatelessWidget {
  final Step _passo;

  ItemStep(this._passo);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Card(
      child: ListTile(
        leading: Icon(Icons.directions_walk),
        title: Text(_passo.aceleracaoMax.toString() + ' m/s²'),
        subtitle: Text(_passo.periodo.toString() + ' ciclo(s)'),
      ),
    );
  }
}

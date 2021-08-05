import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:steps/model/steps.dart';

class ItemStep extends StatelessWidget {
  final Steps _passo;

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
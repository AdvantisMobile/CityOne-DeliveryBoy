import 'package:deliveryboy/src/models/vehicle.dart';
import 'package:deliveryboy/src/repository/vehicle_repository.dart';
import 'package:deliveryboy/src/services/firestore_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:mvc_pattern/mvc_pattern.dart';


import '../../generated/i18n.dart';
import '../../locator.dart';
import '../models/user.dart';
import '../repository/user_repository.dart' as repository;

class UserController extends ControllerMVC {
  User user = new User();
  bool hidePassword = true;
  GlobalKey<FormState> loginFormKey;
  GlobalKey<ScaffoldState> scaffoldKey;
  FirebaseMessaging _firebaseMessaging;
  List<Vehicle> vehicles = [];

  final FirestoreService _firestoreService =
  locator<FirestoreService>();

  UserController() {
    listenForVehicles('driver');
    loginFormKey = new GlobalKey<FormState>();
    this.scaffoldKey = new GlobalKey<ScaffoldState>();
    _firebaseMessaging = FirebaseMessaging();
    _firebaseMessaging.getToken().then((String _deviceToken) {
      user.deviceToken = _deviceToken;
    });
  }

  void login() async {
    if (loginFormKey.currentState.validate()) {
      loginFormKey.currentState.save();
      repository.login(user).then((value) async {
        //print(value.apiToken);
        await _firestoreService.updateUser(value.toMapFirebase(), value.id);
        if (value != null && value.apiToken != null) {
          scaffoldKey?.currentState?.showSnackBar(SnackBar(
            content: Text(S.current.welcome + value.name),
          ));
          Navigator.of(scaffoldKey.currentContext).pushReplacementNamed('/Pages', arguments: 1);
        } else {
          scaffoldKey?.currentState?.showSnackBar(SnackBar(
            content: Text(S.current.wrong_email_or_password),
          ));
        }
      });
    }
  }

  void register() async {
    if (loginFormKey.currentState.validate()) {
      loginFormKey.currentState.save();
      repository.register(user).then((value) async {
        await _firestoreService.createUser(value);
        if (value != null && value.apiToken != null) {
          scaffoldKey?.currentState?.showSnackBar(SnackBar(
            content: Text(S.current.welcome + value.name),
          ));
          Navigator.of(scaffoldKey.currentContext).pushReplacementNamed('/Pages', arguments: 1);
        } else {
          scaffoldKey?.currentState?.showSnackBar(SnackBar(
            content: Text(S.current.wrong_email_or_password),
          ));
        }
      });
    }
  }

  void resetPassword() {
    if (loginFormKey.currentState.validate()) {
      loginFormKey.currentState.save();
      repository.resetPassword(user).then((value) {
        if (value != null && value == true) {
          scaffoldKey?.currentState?.showSnackBar(SnackBar(
            content: Text(S.current.your_reset_link_has_been_sent_to_your_email),
            action: SnackBarAction(
              label: S.current.login,
              onPressed: () {
                Navigator.of(scaffoldKey.currentContext).pushReplacementNamed('/Login');
              },
            ),
            duration: Duration(seconds: 10),
          ));
        } else {
          scaffoldKey?.currentState?.showSnackBar(SnackBar(
            content: Text(S.current.error_verify_email_settings),
          ));
        }
      });
    }
  }

  Future<void> listenForVehicles(String role) async {
    vehicles = [];
    final Stream<Vehicle> stream = await getVehicles();
    stream.listen((Vehicle _vehicle) {
      if (_vehicle.role == role) {
        vehicles.add(_vehicle);
        setState((){});
      }
    }, onError: (a) {
      print(a);
    }, onDone: () {});
  }

  void changeVehicle(value) {
    user.typeId = value;
    setState((){});
  }

}

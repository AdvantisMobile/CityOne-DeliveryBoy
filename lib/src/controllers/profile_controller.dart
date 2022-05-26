import 'package:deliveryboy/locator.dart';
import 'package:deliveryboy/src/services/background_locator_services.dart';
import 'package:deliveryboy/src/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:location_permissions/location_permissions.dart';
import 'package:mvc_pattern/mvc_pattern.dart';

import '../../generated/i18n.dart';
import '../models/order.dart';
import '../models/user.dart';
import '../repository/order_repository.dart';
import '../repository/user_repository.dart';

class ProfileController extends ControllerMVC {
  User user = new User();
  List<Order> recentOrders = [];
  GlobalKey<ScaffoldState> scaffoldKey;
  final FirestoreService _firestoreService =
  locator<FirestoreService>();
  User userFirebase;


  final BackgroundLocatorServices _backgroundLocatorServices =
  locator<BackgroundLocatorServices>();

  ProfileController() {
    this.scaffoldKey = new GlobalKey<ScaffoldState>();
    listenForUser();
    listenUser();
  }

  void listenForUser() {
    getCurrentUser().then((_user) {
      setState(() {
        user = _user;
      });
    });
  }

  void listenForRecentOrders({String message}) async {
    final Stream<Order> stream = await getRecentOrders();
    stream.listen((Order _order) {
      setState(() {
        recentOrders.add(_order);
      });
    }, onError: (a) {
      print(a);
      scaffoldKey?.currentState?.showSnackBar(SnackBar(
        content: Text(S.current.verify_your_internet_connection),
      ));
    }, onDone: () {
      if (message != null) {
        scaffoldKey?.currentState?.showSnackBar(SnackBar(
          content: Text(message),
        ));
      }
    });
  }

  Future<void> refreshProfile() async {
    recentOrders.clear();
    user = new User();
    listenForRecentOrders(message: S.current.orders_refreshed_successfuly);
    listenForUser();
  }


  void listenUser() {
    _firestoreService.getUserStream(currentUser.value.id).listen((userData)  {
      User updateUser = userData;
      if(updateUser != null){
       setState((){
         userFirebase = updateUser;
       });
      }
    });
  }

  Future<void> changeTurn() async{
    if(userFirebase.turn){
      await updateProfile({
        'turn' : false
      });
      _backgroundLocatorServices.stopLocator();

    }else{
      PermissionStatus permissionStatus = await LocationPermissions().checkPermissionStatus();
      if(permissionStatus == PermissionStatus.granted){
        _backgroundLocatorServices.startLocationService();
        await updateProfile({
          'turn' : true
        });
      }else{
        PermissionStatus permission = await LocationPermissions().requestPermissions();

        if(permission != PermissionStatus.granted){
          Get.snackbar('Error', 'Necesitas habilitar los permisos de ubicación');
        }else{
          _backgroundLocatorServices.startLocationService();
          await updateProfile({
            'turn' : true
          });
        }
      }
    }
  }

  Future updateProfile(Map<String, dynamic> data) async {
    try {
      return await _firestoreService.updateUser(data, currentUser.value.id);
    } catch (e) {
      if (e is PlatformException) {
        return e.message;
      }
      return e.toString();
    }
  }

  Future logoutController() async{
    await  _backgroundLocatorServices.stopLocator();
    logout().then((value) {
      Navigator.of(context).pushNamedAndRemoveUntil('/Login', (Route<dynamic> route) => false);
    });
  }

}

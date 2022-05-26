


import 'dart:isolate';
import 'dart:ui';

import 'package:background_locator/background_locator.dart';
import 'package:background_locator/location_dto.dart';
import 'package:background_locator/settings/android_settings.dart';
import 'package:background_locator/settings/ios_settings.dart';
import 'package:background_locator/settings/locator_settings.dart';
import 'package:deliveryboy/locator.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:deliveryboy/src/repository/user_repository.dart' as userRepository;
import 'package:geoflutterfire/geoflutterfire.dart' as GeoFire;

import 'firestore_service.dart';

class BackgroundLocatorServices{
  final geo = GeoFire.Geoflutterfire();


  final FirestoreService _firestoreService =
  locator<FirestoreService>();


  static const String _isolateName = "LocatorIsolate";
  ReceivePort port = ReceivePort();

  void initPlugin(){
    IsolateNameServer.registerPortWithName(port.sendPort, _isolateName);
    port.listen((dynamic data) {
      // do something with data

      print('locator prueba');

      print(data.latitude);
      print(data.longitude);
      _updateCoordinates(data.latitude, data.longitude);
    });
    initPlatformState();

  }

  void initLocator(){
    if (IsolateNameServer.lookupPortByName(
        _isolateName) !=
        null) {
      IsolateNameServer.removePortNameMapping(
          _isolateName);
    }
    initPlugin();
  }

  Future<void> initPlatformState() async {
    await BackgroundLocator.initialize();
  }


  static void callback(LocationDto locationDto) async {
    final SendPort send = IsolateNameServer.lookupPortByName(_isolateName);
    send?.send(locationDto);
  }

//Optional
  static void notificationCallback() {
    print('User clicked on the notification');
  }


  void startLocationService(){
    BackgroundLocator.registerLocationUpdate(
        callback,
        autoStop: false,
        iosSettings: IOSSettings(
            accuracy: LocationAccuracy.NAVIGATION, distanceFilter: 0),
        //optional
        androidSettings: AndroidSettings(
            accuracy: LocationAccuracy.NAVIGATION,
            interval: 5,
            distanceFilter: 0,
            androidNotificationSettings: AndroidNotificationSettings(
                notificationChannelName: 'Location_tracking',
                notificationTitle: 'Obteniendo ubicación',
                notificationMsg: 'CityOne esta obteniendo tu ubicación',
                notificationBigMsg:
                'El turno esta iniciado, por eso cityone obtiene tu ubicación para poder asignarte trabajos cercanos',
                notificationIcon: 'mipmap-hdpi/launcher_icon.png',
                notificationIconColor: Colors.grey,
                notificationTapCallback: notificationCallback)));

  }

  stopLocator(){
    //IsolateNameServer.removePortNameMapping(_isolateName);
    BackgroundLocator.unRegisterLocationUpdate();
  }


  void _updateCoordinates(double latitude, double longitude){
    GeoFire.GeoFirePoint myLocation = geo.point(latitude: latitude, longitude: longitude);
    updateProfile(
        {'coordinates': myLocation.data}
        ,
        userRepository.currentUser.value.id);
  }


  Future updateProfile(Map<String, dynamic> data, String id) async {
    try {
      return await _firestoreService.updateUser(data, id);
    } catch (e) {
      if (e is PlatformException) {
        return e.message;
      }

      return e.toString();
    }
  }

}
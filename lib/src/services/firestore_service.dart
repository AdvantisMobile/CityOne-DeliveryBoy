


import 'dart:async';


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:deliveryboy/src/models/user.dart';

class FirestoreService{

  final CollectionReference _usersCollectionReference =
  FirebaseFirestore.instance.collection('users');


  final StreamController<User> _myUserController =
  StreamController<User>.broadcast();







  Future createUser(User user) async {
    try {
      await _usersCollectionReference.doc(user.id).set(user.toMapFirebase());
    } catch (e) {
      if (e is PlatformException) {
        return e.message;
      }

      return e.toString();
    }
  }

  Future updateUser(Map<String, dynamic> data, String id) async {
    try {
      await _usersCollectionReference.doc(id).update(data);
    } catch (e) {
      if (e is PlatformException) {
        return e.message;
      }

      return e.toString();
    }
  }


  Future getUser(String uid) async {
    try {
      var userData = await _usersCollectionReference.doc(uid).get();
      return User.fromJSON(userData.data());
    } catch (e) {
      if (e is PlatformException) {
        return e.message;
      }

      return e.toString();
    }
  }

  Stream getUserStream(String id) {
    _usersCollectionReference.doc(id).snapshots().listen((userSnapshot) {
      if (userSnapshot.exists) {
        var user = User.fromJSON(userSnapshot.data());
        _myUserController.add(user);
      }
    });
    return _myUserController.stream;
  }





}


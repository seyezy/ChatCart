import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../config/app_config.dart';
import 'backend_api_service.dart';

class ChatCartDevice {
  final String id; final String platform; final bool revoked; final bool current; final DateTime? updatedAt;
  const ChatCartDevice({required this.id,required this.platform,required this.revoked,required this.current,this.updatedAt});
}

class DeviceService {
  final FirebaseMessaging messaging; final BackendApiService backend; StreamSubscription<String>? _tokenSub; String? _uid; String? _deviceId;
  DeviceService({FirebaseMessaging? messaging, BackendApiService? backend}) : messaging=messaging??FirebaseMessaging.instance, backend=backend??BackendApiService();
  Future<String> _getDeviceId() async {final prefs=await SharedPreferences.getInstance();var id=prefs.getString('chatcart_device_id');if(id==null||id.isEmpty){id=const Uuid().v4();await prefs.setString('chatcart_device_id',id);}return id;}
  String get _platform=>kIsWeb?'web':defaultTargetPlatform.name;
  Future<void> start(String uid) async {if(_uid==uid)return;await stop();_uid=uid;_deviceId=await _getDeviceId();await messaging.requestPermission(alert:true,badge:true,sound:true);await messaging.subscribeToTopic(AppConfig.fcmTopic);final token=await messaging.getToken();await backend.registerDevice(deviceId:_deviceId!,platform:_platform,fcmToken:token);_tokenSub=messaging.onTokenRefresh.listen((t){backend.registerDevice(deviceId:_deviceId!,platform:_platform,fcmToken:t);});}
  Future<void> stop() async {await _tokenSub?.cancel();_tokenSub=null;_uid=null;}
  Stream<List<ChatCartDevice>> watchDevices(String uid) async* {final currentId=await _getDeviceId();while(true){final rows=await backend.devices();yield rows.map((d)=>ChatCartDevice(id:d['device_id']?.toString()??'',platform:d['platform']?.toString()??'unknown',revoked:d['revoked_at']!=null,current:d['device_id']==currentId,updatedAt:DateTime.tryParse(d['last_seen_at']?.toString()??''))).toList();await Future<void>.delayed(const Duration(seconds:10));}}
  Future<void> revoke(String deviceId) async {await backend.revokeDevice(deviceId);if(deviceId==_deviceId){await messaging.unsubscribeFromTopic(AppConfig.fcmTopic);await messaging.deleteToken();}}
}

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/chat_models.dart';

class MarketplaceRepository {
  final http.Client client; MarketplaceRepository({http.Client? client}):client=client??http.Client();
  Uri _uri(String path,[Map<String,String>? q]) {final root=AppConfig.apiBaseUrl.endsWith('/')?AppConfig.apiBaseUrl.substring(0,AppConfig.apiBaseUrl.length-1):AppConfig.apiBaseUrl;return Uri.parse('$root/$path').replace(queryParameters:q);}
  Future<List<MarketplaceProduct>> _products(String? category) async {final r=await client.get(_uri('products',category!=null&&category!='All'?{'category':category}:null),headers:{'Accept':'application/json'});if(r.statusCode<200||r.statusCode>=300)throw Exception('Could not load marketplace products.');final d=jsonDecode(r.body) as Map<String,dynamic>;return ((d['products'] as List?)??const[]).map((e)=>MarketplaceProduct.fromJson(Map<String,dynamic>.from(e as Map))).toList();}
  Stream<List<MarketplaceProduct>> watchProducts({String? category}) async* {while(true){yield await _products(category);await Future<void>.delayed(const Duration(seconds:30));}}
  Stream<MarketplaceProduct?> watchProduct(String id) async* {while(true){final r=await client.get(_uri('products/$id'),headers:{'Accept':'application/json'});if(r.statusCode==404){yield null;}else if(r.statusCode>=200&&r.statusCode<300){final d=jsonDecode(r.body) as Map<String,dynamic>;yield MarketplaceProduct.fromJson(Map<String,dynamic>.from(d['product'] as Map));}else{throw Exception('Could not load product.');}await Future<void>.delayed(const Duration(seconds:30));}}
  Future<String> createProduct({required String sellerId,required String title,required String description,required int price,required String category,List<String> imageUrls=const[]}) async {throw UnsupportedError('Product creation is handled by the Laravel seller/admin API in v1.0.0.');}
}

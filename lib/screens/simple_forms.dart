import 'package:flutter/material.dart';
import '../data/azar_db.dart';

class PartyForm extends StatefulWidget { const PartyForm({super.key}); @override State<PartyForm> createState()=>_PartyFormState(); }
class _PartyFormState extends State<PartyForm>{final name=TextEditingController(),phone=TextEditingController();String role='both';bool busy=false;
@override void dispose(){name.dispose();phone.dispose();super.dispose();}
Future<void> save()async{if(name.text.trim().isEmpty)return;setState(()=>busy=true);await AzarDb.instance.saveParty({'name':name.text.trim(),'phone':phone.text.trim(),'role':role,'opening_balance':0});if(mounted)Navigator.pop(context);}
@override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('افزودن شخص')),body:ListView(padding:const EdgeInsets.all(16),children:[TextField(controller:name,decoration:const InputDecoration(labelText:'نام شخص')),const SizedBox(height:12),TextField(controller:phone,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'شماره تماس')),const SizedBox(height:12),DropdownButtonFormField<String>(value:role,decoration:const InputDecoration(labelText:'نوع ارتباط'),items:const [DropdownMenuItem(value:'buyer',child:Text('خریدار')),DropdownMenuItem(value:'seller',child:Text('فروشنده')),DropdownMenuItem(value:'both',child:Text('خریدار و فروشنده')),DropdownMenuItem(value:'carrier',child:Text('حمل / راننده'))],onChanged:(v)=>setState(()=>role=v??'both')),const SizedBox(height:18),FilledButton(onPressed:busy?null:save,child:const Text('ذخیره شخص'))]));}

class VehicleForm extends StatefulWidget {const VehicleForm({super.key});@override State<VehicleForm> createState()=>_VehicleFormState();}
class _VehicleFormState extends State<VehicleForm>{final plate=TextEditingController(),driver=TextEditingController(),phone=TextEditingController();
@override void dispose(){plate.dispose();driver.dispose();phone.dispose();super.dispose();}
Future<void> save()async{if(plate.text.trim().isEmpty)return;await AzarDb.instance.saveVehicle({'plate':plate.text.trim(),'driver':driver.text.trim(),'phone':phone.text.trim()});if(mounted)Navigator.pop(context);}
@override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('ثبت کامیون')),body:ListView(padding:const EdgeInsets.all(16),children:[TextField(controller:plate,decoration:const InputDecoration(labelText:'پلاک کامیون')),const SizedBox(height:12),TextField(controller:driver,decoration:const InputDecoration(labelText:'نام راننده')),const SizedBox(height:12),TextField(controller:phone,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'شماره تماس')),const SizedBox(height:18),FilledButton(onPressed:save,child:const Text('ذخیره کامیون'))]));}

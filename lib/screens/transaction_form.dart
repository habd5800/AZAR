import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../data/azar_db.dart';

class TransactionForm extends StatefulWidget {
  final String kind;
  const TransactionForm({super.key, required this.kind});
  @override State<TransactionForm> createState() => _TransactionFormState();
}
class _TransactionFormState extends State<TransactionForm> {
  final form = GlobalKey<FormState>();
  final gross = TextEditingController(); final tare = TextEditingController(); final price = TextEditingController(); final freight = TextEditingController(); final ticket = TextEditingController(); final note = TextEditingController();
  List<Map<String,Object?>> parties=[]; List<Map<String,Object?>> vehicles=[];
  int? partyId, vehicleId; String material='ماسه شسته'; String freightMode='separate';
  bool saving=false;
  bool get sale => widget.kind=='sale';
  double get net => ((int.tryParse(gross.text)??0)-(int.tryParse(tare.text)??0))/1000;
  int get materialAmount => (net*(int.tryParse(price.text)??0)).round();
  int get freightAmount => int.tryParse(freight.text)??0;
  int get finalAmount => freightMode=='add'?materialAmount+freightAmount:freightMode=='deduct'?materialAmount-freightAmount:materialAmount;
  @override void initState(){super.initState(); _load(); for(final c in [gross,tare,price,freight]){c.addListener(()=>setState((){}));}}
  Future<void> _load() async { parties=await AzarDb.instance.rows('parties'); vehicles=await AzarDb.instance.rows('vehicles'); if(mounted)setState((){}); }
  @override void dispose(){for(final c in [gross,tare,price,freight,ticket,note]){c.dispose();}super.dispose();}
  String _date(){final j=Jalali.fromDateTime(DateTime.now());return '${j.year}/${j.month.toString().padLeft(2,'0')}/${j.day.toString().padLeft(2,'0')}';}
  Future<void> _save() async {
    if(!form.currentState!.validate())return;
    if(net<=0){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('وزن خالص باید بیشتر از صفر باشد.')));return;}
    setState(()=>saving=true);
    try { await AzarDb.instance.saveTransaction({'kind':widget.kind,'date':_date(),'party_id':partyId,'vehicle_id':vehicleId,'material':material,'gross_kg':int.parse(gross.text),'tare_kg':int.parse(tare.text),'net_ton':net,'unit_price':int.tryParse(price.text)??0,'material_amount':materialAmount,'freight':freightAmount,'freight_mode':freightMode,'final_amount':finalAmount,'weigh_ticket':ticket.text,'note':note.text});
      if(mounted){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('سند با موفقیت ذخیره شد.')));Navigator.pop(context);}
    } catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('خطا در ذخیره: $e')));} finally {if(mounted)setState(()=>saving=false);}
  }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(sale?'ثبت فروش مصالح':'ثبت خرید مخلوط')),body:Form(key:form,child:ListView(padding:const EdgeInsets.all(16),children:[
    Text('تاریخ: ${_date()}',style:const TextStyle(fontWeight:FontWeight.bold)),const SizedBox(height:12),
    DropdownButtonFormField<int?>(value:partyId,decoration:InputDecoration(labelText:sale?'خریدار':'فروشنده'),items:[const DropdownMenuItem<int?>(value:null,child:Text('انتخاب طرف حساب')), ...parties.map((p)=>DropdownMenuItem<int?>(value:p['id'] as int,child:Text('${p['name']}')))],onChanged:(v)=>setState(()=>partyId=v)),const SizedBox(height:12),
    DropdownButtonFormField<int?>(value:vehicleId,decoration:const InputDecoration(labelText:'کامیون'),items:[const DropdownMenuItem<int?>(value:null,child:Text('بدون انتخاب')), ...vehicles.map((v)=>DropdownMenuItem<int?>(value:v['id'] as int,child:Text('${v['plate']}')))],onChanged:(v)=>setState(()=>vehicleId=v)),const SizedBox(height:12),
    if(sale) DropdownButtonFormField<String>(value:material,decoration:const InputDecoration(labelText:'نوع مصالح'),items:['ماسه شسته','ماسه شکسته','شن نخودی','شن بادامی','مخلوط','سایر'].map((e)=>DropdownMenuItem(value:e,child:Text(e))).toList(),onChanged:(v)=>setState(()=>material=v??material)) else const ListTile(contentPadding:EdgeInsets.zero,title:Text('نوع معامله: خرید مخلوط')),
    const SizedBox(height:12),_field(gross,'وزن ناخالص (کیلوگرم)',digits:true),const SizedBox(height:12),_field(tare,'وزن خالی (کیلوگرم)',digits:true),const SizedBox(height:12),
    Card(child:ListTile(title:const Text('وزن خالص محاسبه‌شده'),trailing:Text('${net.toStringAsFixed(3)} تن',style:const TextStyle(fontWeight:FontWeight.bold,fontSize:17)))),const SizedBox(height:12),
    _field(price,'قیمت هر تن (ریال)',digits:true),const SizedBox(height:12),_field(freight,'کرایه حمل (ریال)',digits:true),const SizedBox(height:12),
    DropdownButtonFormField<String>(value:freightMode,decoration:const InputDecoration(labelText:'نحوه محاسبه کرایه'),items:const [DropdownMenuItem(value:'separate',child:Text('جدا از مبلغ مصالح')),DropdownMenuItem(value:'add',child:Text('اضافه به مبلغ مصالح')),DropdownMenuItem(value:'deduct',child:Text('کسر از مبلغ مصالح'))],onChanged:(v)=>setState(()=>freightMode=v??'separate')),
    const SizedBox(height:12),_field(ticket,'شماره قبض باسکول'),const SizedBox(height:12),_field(note,'توضیحات'),const SizedBox(height:12),
    Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(children:[_line('مبلغ مصالح',materialAmount),_line('کرایه حمل',freightAmount),const Divider(),_line('مبلغ نهایی سند',finalAmount,bold:true)]))),const SizedBox(height:18),
    FilledButton.icon(onPressed:saving?null:_save,icon:const Icon(Icons.save),label:Text(saving?'در حال ذخیره...':'ذخیره سند'))
  ])));
  Widget _field(TextEditingController c,String label,{bool digits=false})=>TextFormField(controller:c,keyboardType:digits?TextInputType.number:TextInputType.text,decoration:InputDecoration(labelText:label),validator:(v)=>digits&&(v==null||v.trim().isEmpty)?'این فیلد الزامی است':null);
  Widget _line(String label,int value,{bool bold=false})=>Padding(padding:const EdgeInsets.symmetric(vertical:4),child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text(label,style:TextStyle(fontWeight:bold?FontWeight.bold:FontWeight.normal)),Text('${value.toString()} ریال',style:TextStyle(fontWeight:bold?FontWeight.bold:FontWeight.normal))]));
}

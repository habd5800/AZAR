import 'package:flutter/material.dart';
import '../data/azar_db.dart';
import '../utils/formatters.dart';

class ReportsScreen extends StatelessWidget {const ReportsScreen({super.key});
@override Widget build(BuildContext context)=>FutureBuilder<Map<String,int>>(future:AzarDb.instance.totals(),builder:(context,s){if(!s.hasData)return const Center(child:CircularProgressIndicator());final t=s.data!;final balance=t['sales']!-t['purchases']!;return ListView(padding:const EdgeInsets.all(16),children:[const Text('خلاصه عملکرد ثبت‌شده',style:TextStyle(fontSize:19,fontWeight:FontWeight.bold)),const SizedBox(height:12),_row('جمع فروش',t['sales']!),_row('جمع خرید',t['purchases']!),_row('دریافت‌ها',t['received']!),_row('پرداخت‌ها',t['paid']!),_row('کرایه حمل',t['freight']!),const Divider(height:28),_row('اختلاف فروش و خرید (برآورد اولیه)',balance,bold:true),const SizedBox(height:12),const Card(child:Padding(padding:EdgeInsets.all(14),child:Text('توجه: این اختلاف، سود قطعی نیست. برای محاسبه سود واقعی باید بهای خرید مصالح فروخته‌شده به هر فروش تخصیص داده شود. گزارش‌های بازه‌ای و مانده اشخاص در نسخه بعدی تکمیل می‌شوند.')))]);});
Widget _row(String title,int amount,{bool bold=false})=>Card(child:ListTile(title:Text(title,style:TextStyle(fontWeight:bold?FontWeight.bold:FontWeight.normal)),trailing:Text(money(amount),style:TextStyle(fontWeight:bold?FontWeight.bold:FontWeight.w600))));}

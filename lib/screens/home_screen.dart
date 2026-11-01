import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../data/azar_db.dart';
import 'transaction_form.dart';
import 'simple_forms.dart';
import 'reports_screen.dart';

import '../utils/formatters.dart';

String todayJalali() {
  final j = Jalali.fromDateTime(DateTime.now());
  return '${j.year}/${j.month.toString().padLeft(2, '0')}/${j.day.toString().padLeft(2, '0')}';
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  int index = 0;
  int refresh = 0;
  final titles = ['داشبورد', 'خرید و فروش', 'اشخاص', 'ناوگان', 'گزارش‌ها'];
  @override Widget build(BuildContext context) {
    final pages = [Dashboard(key: ValueKey(refresh), onOpen: (kind) => Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionForm(kind: kind))).then((_) => setState(() => refresh++))),
      TransactionsPage(key: ValueKey('tx$refresh'), onRefresh: () => setState(() => refresh++)),
      PartiesPage(key: ValueKey('p$refresh'), onRefresh: () => setState(() => refresh++)),
      FleetPage(key: ValueKey('f$refresh')),
      ReportsScreen(key: ValueKey('r$refresh'))];
    return Scaffold(
      appBar: AppBar(title: Text('آذر | ${titles[index]}'), actions: [Padding(padding: const EdgeInsetsDirectional.only(end: 16), child: Center(child: Text(todayJalali(), style: const TextStyle(fontWeight: FontWeight.w600))))]),
      body: pages[index],
      bottomNavigationBar: NavigationBar(selectedIndex: index, onDestinationSelected: (v) => setState(() => index = v), destinations: const [NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'خانه'), NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'اسناد'), NavigationDestination(icon: Icon(Icons.people_outline), label: 'اشخاص'), NavigationDestination(icon: Icon(Icons.local_shipping_outlined), label: 'ناوگان'), NavigationDestination(icon: Icon(Icons.analytics_outlined), label: 'گزارش')]),
      floatingActionButton: index == 1 ? FloatingActionButton.extended(onPressed: () => showModalBottomSheet(context: context, builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [ListTile(leading: const Icon(Icons.add_shopping_cart), title: const Text('ثبت خرید مخلوط'), onTap: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionForm(kind: 'purchase'))).then((_) => setState(() => refresh++)); }), ListTile(leading: const Icon(Icons.point_of_sale), title: const Text('ثبت فروش مصالح'), onTap: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionForm(kind: 'sale'))).then((_) => setState(() => refresh++)); })]))), icon: const Icon(Icons.add), label: const Text('سند جدید')) : null,
    );
  }
}

class Dashboard extends StatelessWidget {
  final ValueChanged<String> onOpen;
  const Dashboard({super.key, required this.onOpen});
  @override Widget build(BuildContext context) => FutureBuilder<Map<String,int>>(future: AzarDb.instance.totals(), builder: (context, snap) {
    final t = snap.data ?? {};
    return ListView(padding: const EdgeInsets.all(16), children: [
      Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: const Color(0xFF172B4D), borderRadius: BorderRadius.circular(18)), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('سامانه مدیریت کارخانه', style: TextStyle(color: Colors.white70)), SizedBox(height: 8), Text('آذر | AZAR', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold)), SizedBox(height: 4), Text('نسخه آفلاین • اطلاعات روی همین دستگاه ذخیره می‌شود', style: TextStyle(color: Colors.white70))]),),
      const SizedBox(height: 14), Wrap(spacing: 10, runSpacing: 10, children: [metric('فروش ثبت‌شده', money(t['sales']), Icons.trending_up), metric('خرید ثبت‌شده', money(t['purchases']), Icons.shopping_cart), metric('دریافتی', money(t['received']), Icons.call_received), metric('پرداختی', money(t['paid']), Icons.call_made), metric('کرایه ثبت‌شده', money(t['freight']), Icons.local_shipping)]),
      const SizedBox(height: 18), const Text('عملیات سریع', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 8),
      Row(children: [Expanded(child: FilledButton.icon(onPressed: () => onOpen('purchase'), icon: const Icon(Icons.add_shopping_cart), label: const Text('ثبت خرید'))), const SizedBox(width: 8), Expanded(child: FilledButton.icon(onPressed: () => onOpen('sale'), icon: const Icon(Icons.point_of_sale), label: const Text('ثبت فروش')))]),
      const SizedBox(height: 12), Card(child: ListTile(leading: const Icon(Icons.info_outline, color: Color(0xFFF28C28)), title: const Text('یادآوری'), subtitle: const Text('قبل از تعویض یا پاک‌کردن گوشی، از اطلاعات برنامه نسخه پشتیبان تهیه کنید.')))
    ]);
  });
  Widget metric(String title, String value, IconData icon) => SizedBox(width: 170, child: Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: const Color(0xFFF28C28)), const SizedBox(height: 8), Text(title, style: const TextStyle(color: Colors.black54)), const SizedBox(height: 5), Text(value, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))]))));
}

class TransactionsPage extends StatelessWidget {
  final VoidCallback onRefresh;
  const TransactionsPage({super.key, required this.onRefresh});
  @override Widget build(BuildContext context) => FutureBuilder<List<Map<String,Object?>>>(future: AzarDb.instance.rows('transactions', where: 'is_void=0'), builder: (context,s) {
    if (!s.hasData) return const Center(child: CircularProgressIndicator());
    if (s.data!.isEmpty) return const Center(child: Text('هنوز سندی ثبت نشده است.'));
    return ListView.builder(padding: const EdgeInsets.all(12), itemCount: s.data!.length, itemBuilder: (_,i) { final r=s.data![i]; final sale=r['kind']=='sale'; return Card(child: ListTile(leading: CircleAvatar(backgroundColor: sale?Colors.green.shade50:Colors.orange.shade50, child: Icon(sale?Icons.north_east:Icons.south_west, color: sale?Colors.green:Colors.deepOrange)), title: Text('${sale?'فروش':'خرید'} • ${r['material']??'مصالح'}'), subtitle: Text('تاریخ: ${r['date']}  |  تناژ: ${r['net_ton']} تن'), trailing: Text(money(r['final_amount']), style: const TextStyle(fontWeight: FontWeight.bold)))); });
  });
}

class PartiesPage extends StatelessWidget {
  final VoidCallback onRefresh;
  const PartiesPage({super.key, required this.onRefresh});
  @override Widget build(BuildContext context) => Column(children: [Padding(padding: const EdgeInsets.all(12), child: SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PartyForm())).then((_) => onRefresh()), icon: const Icon(Icons.person_add), label: const Text('افزودن شخص')))), Expanded(child: FutureBuilder<List<Map<String,Object?>>>(future: AzarDb.instance.rows('parties'), builder: (context,s) { if (!s.hasData) return const Center(child:CircularProgressIndicator()); if(s.data!.isEmpty) return const Center(child:Text('شخصی ثبت نشده است.')); return ListView(children:s.data!.map((r)=>Card(child:ListTile(leading: const Icon(Icons.person), title:Text('${r['name']}'), subtitle:Text('${r['phone']??''} • ${r['role']}')))).toList()); }))]);
}

class FleetPage extends StatelessWidget {
  const FleetPage({super.key});
  @override Widget build(BuildContext context) => Column(children: [Padding(padding: const EdgeInsets.all(12), child: SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VehicleForm())), icon: const Icon(Icons.add), label: const Text('ثبت کامیون')))), Expanded(child: FutureBuilder<List<Map<String,Object?>>>(future: AzarDb.instance.rows('vehicles'), builder: (context,s) { if (!s.hasData) return const Center(child:CircularProgressIndicator()); if(s.data!.isEmpty) return const Center(child:Text('کامیونی ثبت نشده است.')); return ListView(children:s.data!.map((r)=>Card(child:ListTile(leading: const Icon(Icons.local_shipping), title:Text('${r['plate']}'), subtitle:Text('راننده: ${r['driver']??'—'}')))).toList()); }))]);
}

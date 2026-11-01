import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AzarDb {
  AzarDb._();
  static final AzarDb instance = AzarDb._();
  Database? _db;
  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final base = await getDatabasesPath();
    return openDatabase(p.join(base, 'azar_offline.db'), version: 1, onCreate: (db, version) async {
      await db.execute('''CREATE TABLE parties(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, phone TEXT, role TEXT NOT NULL DEFAULT 'both', opening_balance INTEGER NOT NULL DEFAULT 0, created_at TEXT NOT NULL)''');
      await db.execute('''CREATE TABLE vehicles(id INTEGER PRIMARY KEY AUTOINCREMENT, plate TEXT NOT NULL, driver TEXT, phone TEXT, created_at TEXT NOT NULL)''');
      await db.execute('''CREATE TABLE transactions(id INTEGER PRIMARY KEY AUTOINCREMENT, kind TEXT NOT NULL, date TEXT NOT NULL, party_id INTEGER, vehicle_id INTEGER, material TEXT, gross_kg INTEGER NOT NULL DEFAULT 0, tare_kg INTEGER NOT NULL DEFAULT 0, net_ton REAL NOT NULL DEFAULT 0, unit_price INTEGER NOT NULL DEFAULT 0, material_amount INTEGER NOT NULL DEFAULT 0, freight INTEGER NOT NULL DEFAULT 0, freight_mode TEXT NOT NULL DEFAULT 'separate', final_amount INTEGER NOT NULL DEFAULT 0, weigh_ticket TEXT, note TEXT, created_at TEXT NOT NULL, updated_at TEXT NOT NULL, is_void INTEGER NOT NULL DEFAULT 0)''');
      await db.execute('''CREATE TABLE payments(id INTEGER PRIMARY KEY AUTOINCREMENT, party_id INTEGER NOT NULL, date TEXT NOT NULL, direction TEXT NOT NULL, amount INTEGER NOT NULL, method TEXT NOT NULL, reference TEXT, cheque_status TEXT, note TEXT, created_at TEXT NOT NULL)''');
      await db.execute('''CREATE TABLE audit_log(id INTEGER PRIMARY KEY AUTOINCREMENT, entity TEXT NOT NULL, entity_id INTEGER, action TEXT NOT NULL, before_json TEXT, after_json TEXT, at TEXT NOT NULL)''');
      await db.execute('CREATE INDEX idx_tx_date ON transactions(date)');
      await db.execute('CREATE INDEX idx_tx_party ON transactions(party_id)');
      await db.execute('CREATE INDEX idx_pay_party ON payments(party_id)');
    });
  }

  Future<void> audit(Transaction txn, String entity, int? id, String action, {String? before, String? after}) async {
    await txn.insert('audit_log', {'entity': entity, 'entity_id': id, 'action': action, 'before_json': before, 'after_json': after, 'at': DateTime.now().toIso8601String()});
  }

  Future<int> saveParty(Map<String, Object?> data, {int? id}) async {
    final db = await database;
    return db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      final values = {...data, 'created_at': now};
      final newId = id == null ? await txn.insert('parties', values) : await txn.update('parties', data, where: 'id=?', whereArgs: [id]).then((_) => id);
      await audit(txn, 'party', newId, id == null ? 'create' : 'update', after: data.toString());
      return newId;
    });
  }

  Future<int> saveVehicle(Map<String, Object?> data) async {
    final db = await database;
    return db.transaction((txn) async {
      final id = await txn.insert('vehicles', {...data, 'created_at': DateTime.now().toIso8601String()});
      await audit(txn, 'vehicle', id, 'create', after: data.toString());
      return id;
    });
  }

  Future<int> saveTransaction(Map<String, Object?> data) async {
    final db = await database;
    return db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      final id = await txn.insert('transactions', {...data, 'created_at': now, 'updated_at': now});
      await audit(txn, 'transaction', id, 'create', after: data.toString());
      return id;
    });
  }

  Future<int> savePayment(Map<String, Object?> data) async {
    final db = await database;
    return db.transaction((txn) async {
      final id = await txn.insert('payments', {...data, 'created_at': DateTime.now().toIso8601String()});
      await audit(txn, 'payment', id, 'create', after: data.toString());
      return id;
    });
  }

  Future<List<Map<String, Object?>>> rows(String table, {String? where, List<Object?>? args, String orderBy = 'id DESC'}) async => (await database).query(table, where: where, whereArgs: args, orderBy: orderBy);

  Future<Map<String, int>> totals() async {
    final db = await database;
    final tx = await db.rawQuery("SELECT COALESCE(SUM(CASE WHEN kind='sale' THEN final_amount ELSE 0 END),0) sales, COALESCE(SUM(CASE WHEN kind='purchase' THEN final_amount ELSE 0 END),0) purchases, COALESCE(SUM(freight),0) freight FROM transactions WHERE is_void=0");
    final pay = await db.rawQuery("SELECT COALESCE(SUM(CASE WHEN direction='in' THEN amount ELSE 0 END),0) received, COALESCE(SUM(CASE WHEN direction='out' THEN amount ELSE 0 END),0) paid FROM payments");
    return {'sales': (tx.first['sales'] as num).toInt(), 'purchases': (tx.first['purchases'] as num).toInt(), 'freight': (tx.first['freight'] as num).toInt(), 'received': (pay.first['received'] as num).toInt(), 'paid': (pay.first['paid'] as num).toInt()};
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  test('Verify sqflite_common_ffi_web on Chrome', () async {
    databaseFactory = databaseFactoryFfiWeb;
    final db = await databaseFactory.openDatabase(
      'test_web.db',
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('CREATE TABLE test (id TEXT PRIMARY KEY, name TEXT)');
          await db.insert('test', {'id': '1', 'name': 'PayNest Web'});
        },
      ),
    );

    final results = await db.query('test');
    expect(results.length, 1);
    expect(results.first['name'], 'PayNest Web');
    await db.close();
  });
}

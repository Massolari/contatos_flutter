import "package:path/path.dart";
import "package:sqflite/sqflite.dart";

final String contactTable = "contacts";
final String idColumn = "id";
final String nameColumn = "name";
final String emailColumn = "email";
final String phoneColumn = "phone";
final String imageColumn = "image";

class ContactHelper {
  static final ContactHelper _instance = ContactHelper.internal();

  factory ContactHelper() => _instance;

  ContactHelper.internal();

  Database _db;

  Future<Database> get db async {
    if (_db == null) {
      _db = await initDb();
    }
    return _db;
  }

  Future<Database> initDb() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, "contacts.db");

    return await openDatabase(path, version: 1,
        onCreate: (Database db, int newerVersion) async {
      await db.execute(
          "CREATE TABLE $contactTable ($idColumn PRIMARY KEY, $nameColumn TEXT, $emailColumn TEXT, $phoneColumn TEXT, $imageColumn TEXT)");
    });
  }

  Future<Contact> saveContact(Contact contact) async {
    Database contactDb = await db;
    contact.id = await contactDb.insert(contactTable, contact.toMap());
    return contact;
  }

  Future<Contact> getContact(int id) async {
    Database contactDb = await db;
    List<Map> contactsMap = await contactDb.query(
      contactTable,
      columns: [idColumn, nameColumn, emailColumn, phoneColumn, imageColumn],
      where: "$idColumn = ?",
      whereArgs: [id],
    );
    if (contactsMap.length == 0) {
      return null;
    }
    return Contact.fromMap(contactsMap.first);
  }

  Future<bool> deleteContact(int id) async {
    Database contactDb = await db;
    final int deletedRows = await contactDb.delete(
      contactTable,
      where: "$idColumn = ?",
      whereArgs: [id],
    );
    return deletedRows > 0;
  }

  Future<bool> updateContact(Contact contact) async {
    Database contactDb = await db;
    final int updatedRows = await contactDb.update(
      contactTable,
      contact.toMap(),
      where: "$idColumn = ?",
      whereArgs: [contact.id],
    );
    return updatedRows > 0;
  }

  Future<List<Contact>> getAllContacts() async {
    Database contactDb = await db;
    // contactDb.rawQuery("SELECT * FROM $contactTable");
    List<Map> contactsMap = await contactDb.query(contactTable);
    return contactsMap.map((contact) => Contact.fromMap(contact)).toList();
  }

  Future<int> getNumber() async {
    Database contactDb = await db;
    return Sqflite.firstIntValue(
        await contactDb.rawQuery("SELECT COUNT(*) FROM $contactTable"));
  }

  Future<void> close() async {
    Database contactDb = await db;
    await contactDb.close();
  }
}

class Contact {
  int id;
  String name;
  String email;
  String phone;
  String image;

  Contact.empty();
  Contact(this.id, this.name, this.email, this.phone, this.image);

  Contact.fromMap(Map map) {
    Contact(map[idColumn], map[nameColumn], map[emailColumn], map[phoneColumn],
        map[imageColumn]);
  }

  Map toMap() {
    Map<String, dynamic> map = {
      name: name,
      email: email,
      phone: phone,
      image: image,
    };
    if (id != null) {
      map[idColumn] = id;
    }
    return map;
  }

  @override
  String toString() {
    return "Contact(id: $id, name: $name, email: $email, phone: $phone, image: $image)";
  }
}

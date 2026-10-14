import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Format tanggal penyimpanan: yyyy-MM-dd
String dateKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
String todayKey() => dateKey(DateTime.now());
DateTime parseKey(String k) => DateTime.parse(k);

String fmtTanggalPanjang(DateTime d) =>
    DateFormat('EEEE, d MMM yyyy', 'id_ID').format(d);
String fmtTanggalSingkat(String key) =>
    DateFormat('EEE, d MMM yyyy', 'id_ID').format(parseKey(key));
String fmtJam(DateTime d) => DateFormat('HH:mm').format(d);
String fmtJamDetik(DateTime d) => DateFormat('HH:mm:ss').format(d);
String fmtBulan(DateTime d) => DateFormat('MMMM yyyy', 'id_ID').format(d);
String fmtTanggalJam(DateTime d) =>
    DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(d);

DateTime? toDate(dynamic v) => v is Timestamp ? v.toDate() : null;
int toInt(dynamic v) => v is num ? v.toInt() : 0;

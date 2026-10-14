/// Aturan validasi sesuai Tahap 3 (bagian 4).
class Validators {
  static String? wajib(String? v, [String label = 'Kolom ini']) =>
      (v == null || v.trim().isEmpty) ? '$label wajib diisi' : null;

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
    final ok = RegExp(r'^[\w.+\-]+@[\w\-]+(\.[\w\-]+)+$').hasMatch(v.trim());
    return ok ? null : 'Format email tidak valid';
  }

  static String? kataSandi(String? v) {
    if (v == null || v.isEmpty) return 'Kata sandi wajib diisi';
    if (v.length < 8) return 'Kata sandi minimal 8 karakter';
    return null;
  }

  static String? nik(String? v) {
    if (v == null || v.trim().isEmpty) return 'NIK wajib diisi';
    if (!RegExp(r'^\d{16}$').hasMatch(v.trim())) {
      return 'NIK harus tepat 16 digit angka';
    }
    return null;
  }

  /// Opsional; 13 digit angka bila diisi.
  static String? noBpjs(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    if (!RegExp(r'^\d{13}$').hasMatch(v.trim())) {
      return 'Nomor BPJS harus 13 digit angka';
    }
    return null;
  }

  /// Diawali 08 atau +62, 10-13 digit.
  static String? noHp(String? v) {
    if (v == null || v.trim().isEmpty) return 'Nomor HP wajib diisi';
    final s = v.trim();
    final ok = RegExp(r'^08\d{8,11}$').hasMatch(s) ||
        RegExp(r'^\+62\d{8,11}$').hasMatch(s);
    return ok ? null : 'Nomor HP diawali 08 atau +62, 10-13 digit';
  }

  static String? nama(String? v) {
    if (v == null || v.trim().isEmpty) return 'Nama wajib diisi';
    if (v.trim().length < 3) return 'Nama minimal 3 karakter';
    return null;
  }

  static String? angka(String? v, [String label = 'Nilai']) {
    if (v == null || v.trim().isEmpty) return '$label wajib diisi';
    if (int.tryParse(v.trim()) == null) return '$label harus berupa angka';
    return null;
  }

  /// Tanggal tidak boleh lampau dan maksimal 7 hari ke depan.
  static String? tanggal(DateTime? d) {
    if (d == null) return 'Tanggal wajib dipilih';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final pick = DateTime(d.year, d.month, d.day);
    if (pick.isBefore(today)) return 'Tanggal tidak boleh lampau';
    if (pick.isAfter(today.add(const Duration(days: 7)))) {
      return 'Maksimal 7 hari ke depan';
    }
    return null;
  }
}

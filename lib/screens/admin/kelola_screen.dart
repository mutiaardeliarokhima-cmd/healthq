import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../models/dokter_model.dart';
import '../../models/jadwal_model.dart';
import '../../models/notifikasi_model.dart';
import '../../models/poli_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/jadwal_service.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';
import '../../widgets/common.dart';

final _jamRegex = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

/// Dialog formulir generik dengan tombol Batal / Simpan.
Future<void> _formDialog(
  BuildContext context, {
  required String title,
  required GlobalKey<FormState> formKey,
  required Widget Function(StateSetter) body,
  required Future<void> Function() onSave,
}) {
  var saving = false;
  return showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setD) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(title),
        content: SizedBox(
          width: 340,
          child: SingleChildScrollView(child: Form(key: formKey, child: body(setD))),
        ),
        actions: [
          TextButton(onPressed: saving ? null : () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(88, 48)),
            onPressed: saving
                ? null
                : () async {
                    if (!formKey.currentState!.validate()) return;
                    setD(() => saving = true);
                    try {
                      await onSave();
                      if (ctx.mounted) Navigator.pop(ctx);
                    } catch (e) {
                      setD(() => saving = false);
                      if (context.mounted) showSnack(context, AuthService.pesanError(e), error: true);
                    }
                  },
            child: saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : const Text('Simpan'),
          ),
        ],
      ),
    ),
  );
}

Widget _gap() => const SizedBox(height: 12);

/// Baris daftar dengan aksi ubah/hapus.
class _Item extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? extra;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  const _Item({required this.leading, required this.title, this.subtitle, this.extra, this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
        child: Row(children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: text.titleSmall),
              if (subtitle != null) Text(subtitle!, style: text.bodySmall),
              if (extra != null) extra!,
            ]),
          ),
          if (onEdit != null)
            IconButton(tooltip: 'Ubah', onPressed: onEdit, icon: const Icon(Icons.edit_outlined)),
          if (onDelete != null)
            IconButton(
                tooltip: 'Hapus', onPressed: onDelete, icon: const Icon(Icons.delete_outline_rounded, color: AppColors.red)),
        ]),
      ),
    );
  }
}

Widget _badge(String s) => Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: AppColors.mint.withOpacity(.6), borderRadius: BorderRadius.circular(12)),
      child: Text(s, style: const TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.w900)),
    );

Future<bool> _hapus(BuildContext context, String nama) => konfirmasi(context,
    judul: 'Hapus data?', isi: '$nama akan dihapus permanen.', ya: 'Hapus', bahaya: true);

/// Kelola Poli, Dokter, Jadwal, Petugas, dan Pengumuman.
class KelolaScreen extends StatelessWidget {
  const KelolaScreen({super.key});

  Future<void> _isiContoh(BuildContext context) async {
    final ya = await konfirmasi(context,
        judul: 'Isi data contoh?',
        isi: 'Menambahkan 4 poli, 4 dokter, jadwal 9 hari ke depan, dan 2 pengumuman. Data dengan ID sama akan ditimpa.',
        ya: 'Isi Data');
    if (!ya || !context.mounted) return;
    try {
      await context.read<JadwalService>().isiDataContoh();
      if (context.mounted) showSnack(context, 'Data contoh berhasil ditambahkan.');
    } catch (e) {
      if (context.mounted) showSnack(context, AuthService.pesanError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kelola Data'),
          actions: [
            PopupMenuButton<String>(
              tooltip: 'Menu',
              onSelected: (_) => _isiContoh(context),
              itemBuilder: (_) => const [PopupMenuItem(value: 'seed', child: Text('Isi data contoh'))],
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AppColors.primary,
            indicatorColor: AppColors.primary,
            unselectedLabelColor: AppColors.muted,
            tabs: [
              Tab(text: 'Poli'),
              Tab(text: 'Dokter'),
              Tab(text: 'Jadwal'),
              Tab(text: 'Petugas'),
              Tab(text: 'Pengumuman'),
            ],
          ),
        ),
        body: const TabBarView(children: [
          _PoliTab(),
          _DokterTab(),
          _JadwalTab(),
          _PetugasTab(),
          _PengumumanTab(),
        ]),
      ),
    );
  }
}

// ---------------- Poli ----------------
class _PoliTab extends StatelessWidget {
  const _PoliTab();

  Future<void> _form(BuildContext context, PoliModel? p) async {
    final svc = context.read<JadwalService>();
    final key = GlobalKey<FormState>();
    final nama = TextEditingController(text: p?.namaPoli ?? '');
    final kode = TextEditingController(text: p?.kodePoli ?? '');
    final buka = TextEditingController(text: p?.jamBuka ?? '08:00');
    final tutup = TextEditingController(text: p?.jamTutup ?? '14:00');
    final durasi = TextEditingController(text: '${p?.rataDurasiMenit ?? 10}');
    var aktif = p?.aktif ?? true;

    String? jam(String? v) => (v != null && _jamRegex.hasMatch(v.trim())) ? null : 'Format HH:mm';

    await _formDialog(
      context,
      title: p == null ? 'Tambah Poli' : 'Ubah Poli',
      formKey: key,
      body: (setD) => Column(mainAxisSize: MainAxisSize.min, children: [
        TextFormField(controller: nama, decoration: const InputDecoration(labelText: 'Nama poli'), validator: (v) => Validators.wajib(v, 'Nama poli')),
        _gap(),
        TextFormField(
            controller: kode,
            maxLength: 2,
            decoration: const InputDecoration(labelText: 'Kode huruf (mis. A)', counterText: ''),
            validator: (v) => Validators.wajib(v, 'Kode')),
        _gap(),
        Row(children: [
          Expanded(child: TextFormField(controller: buka, decoration: const InputDecoration(labelText: 'Jam buka'), validator: jam)),
          const SizedBox(width: 10),
          Expanded(child: TextFormField(controller: tutup, decoration: const InputDecoration(labelText: 'Jam tutup'), validator: jam)),
        ]),
        _gap(),
        TextFormField(
            controller: durasi,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Rata-rata durasi (menit)'),
            validator: (v) => Validators.angka(v, 'Durasi')),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Poli dibuka'),
          value: aktif,
          onChanged: (v) => setD(() => aktif = v),
        ),
      ]),
      onSave: () => svc.simpanPoli(PoliModel(
        poliId: p?.poliId ?? '',
        namaPoli: nama.text.trim(),
        kode: kode.text.trim(),
        jamBuka: buka.text.trim(),
        jamTutup: tutup.text.trim(),
        rataDurasiMenit: int.parse(durasi.text.trim()),
        aktif: aktif,
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.read<JadwalService>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _form(context, null),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Poli'),
      ),
      body: StreamBuilder<List<PoliModel>>(
        stream: svc.streamPoli(),
        builder: (context, snap) {
          if (!snap.hasData) return const LoadingView();
          final list = snap.data!;
          if (list.isEmpty) {
            return const EmptyState(icon: Icons.local_hospital_outlined, title: 'Belum ada poli', message: 'Tambahkan poli atau gunakan menu "Isi data contoh".');
          }
          return ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 90), children: [
            for (final p in list)
              _Item(
                leading: _badge(p.kodePoli),
                title: 'Poli ${p.namaPoli}',
                subtitle: '${p.jamBuka} - ${p.jamTutup}, ${p.rataDurasiMenit} mnt/pasien',
                extra: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(p.aktif ? 'Buka' : 'Tutup',
                      style: TextStyle(fontWeight: FontWeight.w800, color: p.aktif ? AppColors.primary : AppColors.red)),
                ),
                onEdit: () => _form(context, p),
                onDelete: () async {
                  if (await _hapus(context, 'Poli ${p.namaPoli}')) await svc.hapusPoli(p.poliId);
                },
              ),
          ]);
        },
      ),
    );
  }
}

// ---------------- Dokter ----------------
class _DokterTab extends StatelessWidget {
  const _DokterTab();

  Future<void> _form(BuildContext context, DokterModel? d) async {
    final svc = context.read<JadwalService>();
    final key = GlobalKey<FormState>();
    final nama = TextEditingController(text: d?.nama ?? '');
    final spes = TextEditingController(text: d?.spesialis ?? '');
    await _formDialog(
      context,
      title: d == null ? 'Tambah Dokter' : 'Ubah Dokter',
      formKey: key,
      body: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
        TextFormField(controller: nama, decoration: const InputDecoration(labelText: 'Nama dokter'), validator: Validators.nama),
        _gap(),
        TextFormField(controller: spes, decoration: const InputDecoration(labelText: 'Spesialis / bidang layanan'), validator: (v) => Validators.wajib(v, 'Spesialis')),
      ]),
      onSave: () => svc.simpanDokter(DokterModel(dokterId: d?.dokterId ?? '', nama: nama.text.trim(), spesialis: spes.text.trim())),
    );
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.read<JadwalService>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _form(context, null),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Dokter'),
      ),
      body: StreamBuilder<List<DokterModel>>(
        stream: svc.streamDokter(),
        builder: (context, snap) {
          if (!snap.hasData) return const LoadingView();
          final list = snap.data!;
          if (list.isEmpty) return const EmptyState(icon: Icons.medical_services_outlined, title: 'Belum ada dokter');
          return ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 90), children: [
            for (final d in list)
              _Item(
                leading: const CircleAvatar(
                    radius: 22, backgroundColor: AppColors.sky, child: Icon(Icons.medical_services_rounded, color: AppColors.primary)),
                title: d.nama,
                subtitle: d.spesialis,
                onEdit: () => _form(context, d),
                onDelete: () async {
                  if (await _hapus(context, d.nama)) await svc.hapusDokter(d.dokterId);
                },
              ),
          ]);
        },
      ),
    );
  }
}

// ---------------- Jadwal dan kuota ----------------
class _JadwalTab extends StatelessWidget {
  const _JadwalTab();

  Future<void> _form(BuildContext context, List<PoliModel> poli, List<DokterModel> dokter, JadwalModel? j) async {
    if (poli.isEmpty || dokter.isEmpty) {
      showSnack(context, 'Tambahkan poli dan dokter terlebih dahulu.', error: true);
      return;
    }
    final svc = context.read<JadwalService>();
    final key = GlobalKey<FormState>();
    String? poliId = j?.poliId ?? poli.first.poliId;
    String? dokterId = j?.dokterId ?? dokter.first.dokterId;
    var tgl = j == null ? DateTime.now() : parseKey(j.tanggal);
    final kuota = TextEditingController(text: '${j?.kuota ?? 20}');

    await _formDialog(
      context,
      title: j == null ? 'Tambah Jadwal' : 'Ubah Jadwal',
      formKey: key,
      body: (setD) => Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<String>(
          value: poliId,
          decoration: const InputDecoration(labelText: 'Poli'),
          items: [for (final p in poli) DropdownMenuItem(value: p.poliId, child: Text('Poli ${p.namaPoli}'))],
          onChanged: j == null ? (v) => setD(() => poliId = v) : null,
        ),
        _gap(),
        DropdownButtonFormField<String>(
          value: dokterId,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Dokter'),
          items: [for (final d in dokter) DropdownMenuItem(value: d.dokterId, child: Text(d.nama, overflow: TextOverflow.ellipsis))],
          onChanged: (v) => setD(() => dokterId = v),
        ),
        _gap(),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: j != null
              ? null
              : () async {
                  final d = await showDatePicker(
                      context: key.currentContext!,
                      initialDate: tgl,
                      firstDate: DateTime.now().subtract(const Duration(days: 1)),
                      lastDate: DateTime.now().add(const Duration(days: 90)));
                  if (d != null) setD(() => tgl = d);
                },
          child: InputDecorator(
            decoration: const InputDecoration(labelText: 'Tanggal', suffixIcon: Icon(Icons.calendar_today_rounded)),
            child: Text(fmtTanggalSingkat(dateKey(tgl))),
          ),
        ),
        _gap(),
        TextFormField(
            controller: kuota,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Kuota harian'),
            validator: (v) => Validators.angka(v, 'Kuota')),
      ]),
      onSave: () => svc.simpanJadwal(
        poliId: poliId!,
        dokterId: dokterId!,
        tanggal: dateKey(tgl),
        kuota: int.parse(kuota.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.read<JadwalService>();
    return StreamBuilder<List<PoliModel>>(
      stream: svc.streamPoli(),
      builder: (context, pSnap) => StreamBuilder<List<DokterModel>>(
        stream: svc.streamDokter(),
        builder: (context, dSnap) => StreamBuilder<List<JadwalModel>>(
          stream: svc.streamJadwalMulai(todayKey()),
          builder: (context, jSnap) {
            final poli = pSnap.data ?? <PoliModel>[];
            final dokter = dSnap.data ?? <DokterModel>[];
            final poliMap = {for (final p in poli) p.poliId: p};
            final dokterMap = {for (final d in dokter) d.dokterId: d};
            return Scaffold(
              backgroundColor: Colors.transparent,
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () => _form(context, poli, dokter, null),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Tambah Jadwal'),
              ),
              body: !jSnap.hasData
                  ? const LoadingView()
                  : (jSnap.data!.isEmpty
                      ? const EmptyState(icon: Icons.calendar_month_outlined, title: 'Belum ada jadwal', message: 'Atur jadwal dokter dan kuota harian per poli.')
                      : ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 90), children: [
                          for (final j in jSnap.data!)
                            _Item(
                              leading: _badge(poliMap[j.poliId]?.kodePoli ?? '?'),
                              title: '${fmtTanggalSingkat(j.tanggal)}, Poli ${poliMap[j.poliId]?.namaPoli ?? '-'}',
                              subtitle: dokterMap[j.dokterId]?.nama ?? '-',
                              extra: Text('Kuota ${j.terpakai}/${j.kuota} terpakai',
                                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 14)),
                              onEdit: () => _form(context, poli, dokter, j),
                              onDelete: () async {
                                if (await _hapus(context, 'Jadwal ${j.tanggal}')) await svc.hapusJadwal(j.jadwalId);
                              },
                            ),
                        ])),
            );
          },
        ),
      ),
    );
  }
}

// ---------------- Akun petugas ----------------
class _PetugasTab extends StatelessWidget {
  const _PetugasTab();

  Future<void> _form(BuildContext context) async {
    final auth = context.read<AuthService>();
    final key = GlobalKey<FormState>();
    final nama = TextEditingController();
    final email = TextEditingController();
    final pass = TextEditingController();
    final hp = TextEditingController();
    await _formDialog(
      context,
      title: 'Tambah Akun Petugas',
      formKey: key,
      body: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
        TextFormField(controller: nama, decoration: const InputDecoration(labelText: 'Nama petugas'), validator: Validators.nama),
        _gap(),
        TextFormField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email'), validator: Validators.email),
        _gap(),
        TextFormField(controller: hp, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Nomor HP'), validator: Validators.noHp),
        _gap(),
        TextFormField(controller: pass, decoration: const InputDecoration(labelText: 'Kata sandi awal (min. 8)'), validator: Validators.kataSandi),
      ]),
      onSave: () => auth.createStaffAccount(nama: nama.text, email: email.text, password: pass.text, noHp: hp.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _form(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Tambah Petugas'),
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: auth.streamPetugas(),
        builder: (context, snap) {
          if (snap.hasError) {
            return const EmptyState(icon: Icons.lock_outline_rounded, title: 'Tidak dapat memuat akun petugas');
          }
          if (!snap.hasData) return const LoadingView();
          final list = snap.data!;
          if (list.isEmpty) {
            return const EmptyState(icon: Icons.badge_outlined, title: 'Belum ada akun petugas', message: 'Buat akun untuk petugas pendaftaran.');
          }
          return ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 90), children: [
            for (final u in list)
              _Item(
                leading: CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primary,
                    child: Text(u.nama.isEmpty ? '?' : u.nama[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
                title: u.nama,
                subtitle: '${u.email}\n${u.noHp}',
              ),
          ]);
        },
      ),
    );
  }
}

// ---------------- Pengumuman ----------------
class _PengumumanTab extends StatelessWidget {
  const _PengumumanTab();

  Future<void> _form(BuildContext context, PengumumanModel? p) async {
    final svc = context.read<JadwalService>();
    final key = GlobalKey<FormState>();
    final judul = TextEditingController(text: p?.judul ?? '');
    final isi = TextEditingController(text: p?.isi ?? '');
    await _formDialog(
      context,
      title: p == null ? 'Tambah Pengumuman' : 'Ubah Pengumuman',
      formKey: key,
      body: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
        TextFormField(controller: judul, decoration: const InputDecoration(labelText: 'Judul'), validator: (v) => Validators.wajib(v, 'Judul')),
        _gap(),
        TextFormField(controller: isi, maxLines: 4, decoration: const InputDecoration(labelText: 'Isi pengumuman atau tips kesehatan'), validator: (v) => Validators.wajib(v, 'Isi')),
      ]),
      onSave: () => svc.simpanPengumuman(id: p?.id, judul: judul.text.trim(), isi: isi.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.read<JadwalService>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _form(context, null),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah'),
      ),
      body: StreamBuilder<List<PengumumanModel>>(
        stream: svc.streamPengumuman(),
        builder: (context, snap) {
          if (!snap.hasData) return const LoadingView();
          final list = snap.data!;
          if (list.isEmpty) return const EmptyState(icon: Icons.campaign_outlined, title: 'Belum ada pengumuman');
          return ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 90), children: [
            for (final p in list)
              _Item(
                leading: const Icon(Icons.campaign_rounded, color: AppColors.orange, size: 30),
                title: p.judul,
                subtitle: p.isi,
                onEdit: () => _form(context, p),
                onDelete: () async {
                  if (await _hapus(context, p.judul)) await svc.hapusPengumuman(p.id);
                },
              ),
          ]);
        },
      ),
    );
  }
}

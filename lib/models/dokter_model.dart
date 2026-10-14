class DokterModel {
  final String dokterId;
  final String nama;
  final String spesialis;

  const DokterModel({required this.dokterId, required this.nama, this.spesialis = ''});

  factory DokterModel.fromMap(String id, Map<String, dynamic> m) => DokterModel(
        dokterId: id,
        nama: m['nama'] ?? '',
        spesialis: m['spesialis'] ?? '',
      );

  Map<String, dynamic> toMap() => {'nama': nama, 'spesialis': spesialis};
}

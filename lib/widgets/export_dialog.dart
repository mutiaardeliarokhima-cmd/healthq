import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/theme.dart';
import '../utils/report.dart';
import 'common.dart';

/// Ekspor laporan ke CSV (disalin ke clipboard). Ekspor PDF ditunda ke pengembangan lanjutan.
Future<void> showExportDialog(BuildContext context, ReportSummary r, String label) {
  final csv = r.toCsv();
  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Text('Ekspor Laporan $label'),
      content: SizedBox(
        width: 360,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${r.data.length} baris data dalam format CSV.', style: Theme.of(ctx).textTheme.bodySmall),
          const SizedBox(height: 10),
          Container(
            constraints: const BoxConstraints(maxHeight: 220),
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.tint, borderRadius: BorderRadius.circular(12)),
            child: SingleChildScrollView(
              child: SelectableText(csv, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
            ),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size(88, 48)),
          icon: const Icon(Icons.copy_rounded),
          label: const Text('Salin CSV'),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: csv));
            if (ctx.mounted) Navigator.pop(ctx);
            if (context.mounted) showSnack(context, 'CSV disalin. Tempel ke aplikasi spreadsheet.');
          },
        ),
      ],
    ),
  );
}

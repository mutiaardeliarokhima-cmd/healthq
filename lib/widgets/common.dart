import 'package:flutter/material.dart';
import '../app/theme.dart';

/// Kartu standar: satu gaya untuk seluruh aplikasi.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;
  final bool outlined;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.onTap,
    this.outlined = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: outlined ? Border.all(color: AppColors.line, width: 1.2) : null,
          ),
          child: child,
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 22, 0, 10),
        child: Row(children: [
          Expanded(child: Text(text, style: Theme.of(context).textTheme.titleMedium)),
          if (trailing != null) trailing!,
        ]),
      );
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  const EmptyState({super.key, required this.icon, required this.title, this.message, this.action});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(color: AppColors.sky, shape: BoxShape.circle),
              child: Icon(icon, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 18),
            Text(title, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(message!, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
            ],
            if (action != null) ...[const SizedBox(height: 20), action!],
          ]),
        ),
      );
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(color: AppColors.primary));
}

void showSnack(BuildContext context, String msg, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.red : AppColors.ink,
    ));
}

Future<bool> konfirmasi(BuildContext context,
    {required String judul, required String isi, String ya = 'Ya', String tidak = 'Kembali', bool bahaya = false}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(judul),
      content: Text(isi),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tidak)),
        FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: bahaya ? AppColors.red : AppColors.primary,
              minimumSize: const Size(88, 48)),
          onPressed: () => Navigator.pop(context, true),
          child: Text(ya),
        ),
      ],
    ),
  );
  return r ?? false;
}

/// Pilihan label + ikon pada bottom navigation.
class NavItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  const NavItem(this.label, this.icon, this.selectedIcon);
}

/// Bottom navigation berbeda untuk tiap peran.
class RoleShell extends StatefulWidget {
  final List<NavItem> items;
  final List<Widget> pages;
  final int initialIndex;
  const RoleShell({super.key, required this.items, required this.pages, this.initialIndex = 0});

  @override
  State<RoleShell> createState() => _RoleShellState();
}

class _RoleShellState extends State<RoleShell> {
  late int _i = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(bottom: false, child: IndexedStack(index: _i, children: widget.pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _i,
        onDestinationSelected: (v) => setState(() => _i = v),
        destinations: [
          for (final it in widget.items)
            NavigationDestination(
                icon: Icon(it.icon), selectedIcon: Icon(it.selectedIcon), label: it.label),
        ],
      ),
    );
  }
}

/// Dipakai halaman di dalam shell agar bisa pindah tab.
class ShellTabs extends InheritedWidget {
  final void Function(int) goTo;
  const ShellTabs({super.key, required this.goTo, required super.child});
  static ShellTabs? of(BuildContext c) => c.dependOnInheritedWidgetOfExactType<ShellTabs>();
  @override
  bool updateShouldNotify(ShellTabs old) => false;
}

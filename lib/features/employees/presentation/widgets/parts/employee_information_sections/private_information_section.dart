part of '../../employee_information_sections.dart';

class _InformationSection extends StatelessWidget {
  const _InformationSection({required this.title, required this.rows});

  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: AppSpacing.s),
      SurfaceCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            for (var index = 0; index < rows.length; index++) ...[
              if (index > 0)
                const Divider(height: 1, indent: 58, endIndent: 14),
              rows[index],
            ],
          ],
        ),
      ),
    ],
  );
}

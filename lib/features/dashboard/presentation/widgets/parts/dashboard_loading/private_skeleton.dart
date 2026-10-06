part of '../../dashboard_loading.dart';

class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.height, this.width});
  final double height;
  final double? width;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.field,
        borderRadius: BorderRadius.circular(AppRadii.l),
      ),
    ),
  );
}

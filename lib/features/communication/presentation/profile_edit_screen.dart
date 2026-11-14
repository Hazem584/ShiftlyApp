import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/widgets/app_content_loading.dart';
import 'package:shiftly/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:shiftly/features/profile/presentation/widgets/profile_edit_form.dart';

import 'communication_page.dart';

class ProfileEditScreen extends StatelessWidget {
  const ProfileEditScreen({required this.cubit, super.key});
  final ProfileCubit cubit;
  @override
  Widget build(BuildContext context) => BlocBuilder<ProfileCubit, ProfileState>(
    bloc: cubit,
    builder: (context, state) => state is ProfileLoaded
        ? ProfileEditForm(
            key: const Key('profile-editor'),
            profile: state.profile,
            action: state.action,
            onCancel: () => Navigator.pop(context),
            onSaved: () => Navigator.pop(context),
          )
        : const CommunicationPage(
            title: 'Edit information',
            child: AppContentLoading(),
          ),
  );
}

part of '../../profile_edit_form.dart';

class ProfileEditForm extends StatefulWidget {
  const ProfileEditForm({
    super.key,
    required this.profile,
    required this.action,
    required this.onCancel,
    required this.onSaved,
  });

  final ManagerProfile profile;
  final ProfileAction action;
  final VoidCallback onCancel;
  final VoidCallback onSaved;

  @override
  State<ProfileEditForm> createState() => _ProfileEditFormState();
}

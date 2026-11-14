import 'package:flutter/material.dart';

import 'communication_appearance.dart';

Future<T?> openCommunicationPage<T>(BuildContext context, Widget page) =>
    Navigator.of(context, rootNavigator: true).push<T>(
      MaterialPageRoute<T>(
        builder: (_) => CommunicationAppearance(child: page),
      ),
    );

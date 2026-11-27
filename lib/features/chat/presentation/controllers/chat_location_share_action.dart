import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/presentation/controllers/chat_location_position.dart';
import 'package:shiftly/features/chat/presentation/controllers/chat_media_capture.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_conversation_cubit.dart';
import 'package:shiftly/features/chat/presentation/screens/chat_media_review_screen.dart';

Future<void> shareChatLocation(ChatMediaCapture capture) async {
  if (capture.mediaBusy) return;
  final context = capture.context;
  capture.setMediaBusy(true);
  try {
    final pos = await acquireChatLocationPosition(capture);
    if (pos == null) return;
    final location = ChatLocation(
      latitude: (pos.latitude * 1000000).roundToDouble() / 1000000,
      longitude: (pos.longitude * 1000000).roundToDouble() / 1000000,
    );
    if (!context.mounted || !location.isValid || !capture.active) return;
    final conversation = context.read<ChatConversationCubit>();
    final generation = conversation.generation;
    final decision = await Navigator.push<ChatMediaDecision>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ChatMediaReviewScreen(kind: 'LOCATION', location: location),
      ),
    );
    if (decision != null &&
        capture.active &&
        conversation.generation == generation) {
      await conversation.sendLocation(
        ChatLocation(
          latitude: location.latitude,
          longitude: location.longitude,
          label: decision.caption?.isEmpty == true ? null : decision.caption,
        ),
      );
    }
  } on TimeoutException {
    if (context.mounted && capture.active) {
      Fluttertoast.showToast(msg: context.tr('Location request timed out.'));
    }
  } catch (_) {
    if (context.mounted && capture.active) {
      Fluttertoast.showToast(
        msg: context.tr('Your location is currently unavailable.'),
      );
    }
  } finally {
    if (capture.active) capture.setMediaBusy(false);
  }
}

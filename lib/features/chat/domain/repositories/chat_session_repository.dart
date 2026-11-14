import 'package:shiftly/core/session/feature_scope.dart';

abstract interface class ChatSessionRepository {
  void bindChatSession(FeatureSessionScope? scope);
}

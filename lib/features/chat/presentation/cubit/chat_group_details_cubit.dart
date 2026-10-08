import 'package:equatable/equatable.dart';
import 'package:shiftly/features/chat/data/cache/chat_cache_database.dart';
import 'package:shiftly/features/chat/data/cache/chat_cache_scope.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/chat/data/chat_models.dart';
import 'package:shiftly/features/chat/data/chat_repository.dart';

part 'parts/chat_group_details_cubit/chat_group_details_state.dart';
part 'parts/chat_group_details_cubit/chat_group_details_cubit.dart';

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:shiftly/core/storage/active_workspace_storage.dart';
import 'package:shiftly/features/auth/domain/entities/auth_session.dart';
import 'package:shiftly/features/auth/domain/repositories/authentication_service.dart';

part 'parts/auth_interceptor/request_options_keys.dart';
part 'parts/auth_interceptor/auth_interceptor.dart';

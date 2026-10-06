import 'dart:typed_data';

import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/features/chat/data/chat_models.dart';
import 'package:shiftly/features/chat/data/chat_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'parts/signed_chat_upload_client/chat_storage_uploader.dart';
part 'parts/signed_chat_upload_client/supabase_chat_storage_uploader.dart';
part 'parts/signed_chat_upload_client/signed_chat_upload_client.dart';

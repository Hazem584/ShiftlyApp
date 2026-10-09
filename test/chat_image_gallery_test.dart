
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/auth/data/models/current_user.dart';
import 'package:shiftly/features/chat/data/chat_image_gallery.dart';
import 'package:shiftly/features/chat/data/chat_models.dart';
import 'package:shiftly/features/chat/data/chat_repository.dart';

const _channel = MethodChannel('shiftly/chat_gallery');
const _scope = FeatureSessionScope(
  userId: 'user',
  workspaceId: 'workspace',
  membershipId: 'member',
  role: WorkspaceRole.manager,
  timezone: 'Etc/UTC',
);
final _bytes = Uint8List.fromList([0xff, 0xd8, 0xff, 0xd9]);
ChatMessage _image({int size = 4}) => ChatMessage(
  id: 'image-id',
  groupId: 'group',
  type: 'IMAGE',
  sender: const ChatSender(membershipId: 'member'),
  createdAt: DateTime.utc(2026),
  attachment: ChatAttachment(
    id: 'attachment',
    category: 'IMAGE',
    mimeType: 'image/jpeg',
    sizeBytes: size,
  ),
);

class _Repository implements ChatRepository {
  int signedRequests = 0;
  @override
  Future<ChatMediaUrl> mediaUrl(
    String workspaceId,
    String groupId,
    String messageId,
  ) async {
    signedRequests++;
    return ChatMediaUrl(
      url: Uri.parse('https://storage.example/image?token=$signedRequests'),
      expiresAt: DateTime.utc(2099),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <MethodCall>[];
  setUp(() {
    calls.clear();
    messenger.setMockMethodCallHandler(_channel, (call) async {
      calls.add(call);
      return true;
    });
  });
  tearDown(() => messenger.setMockMethodCallHandler(_channel, null));

  Dio client({
    List<int>? bytes,
    void Function()? onDownload,
    bool expiredOnce = false,
  }) {
    var attempt = 0;
    return Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(
              options.headers.keys.map((key) => key.toLowerCase()),
              isNot(contains('authorization')),
            );
            expect(options.followRedirects, isFalse);
            onDownload?.call();
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: expiredOnce && attempt++ == 0 ? 403 : 200,
                data: ResponseBody.fromBytes(
                  bytes ?? _bytes,
                  expiredOnce && attempt == 1 ? 403 : 200,
                ),
              ),
            );
          },
        ),
      );
  }

  test('exports original verified image bytes to gallery', () async {
    final repository = _Repository();
    await ChatImageGallery(downloadClient: client()).save(
      message: _image(),
      repository: repository,
      session: _scope,
      hasAccess: () => true,
    );
    expect(repository.signedRequests, 1);
    expect(calls, hasLength(1));
    expect(calls.single.method, 'saveImage');
    final arguments = calls.single.arguments as Map;
    expect(arguments['bytes'], _bytes);
    expect(arguments['mimeType'], 'image/jpeg');
    expect(arguments['name'], matches(r'^shiftly_\d+\.jpg$'));
  });

  test('lost access while downloading prevents gallery export', () async {
    var authorized = true;
    final gallery = ChatImageGallery(
      downloadClient: client(onDownload: () => authorized = false),
    );
    await expectLater(
      gallery.save(
        message: _image(),
        repository: _Repository(),
        session: _scope,
        hasAccess: () => authorized,
      ),
      throwsStateError,
    );
    expect(calls, isEmpty);
  });

  test('wrong image size or contents never reaches gallery', () async {
    for (final bytes in [
      [1, 2, 3, 4],
      [0xff, 0xd8, 0xff, 0xd9, 0],
    ]) {
      await expectLater(
        ChatImageGallery(downloadClient: client(bytes: bytes)).save(
          message: _image(),
          repository: _Repository(),
          session: _scope,
          hasAccess: () => true,
        ),
        throwsFormatException,
      );
    }
    expect(calls, isEmpty);
  });

  test(
    'photo permission rejection is reported without claiming success',
    () async {
      messenger.setMockMethodCallHandler(_channel, (_) async {
        throw PlatformException(code: 'PHOTO_PERMISSION_DENIED');
      });
      await expectLater(
        ChatImageGallery(downloadClient: client()).save(
          message: _image(),
          repository: _Repository(),
          session: _scope,
          hasAccess: () => true,
        ),
        throwsA(
          isA<PlatformException>().having(
            (error) => error.code,
            'code',
            'PHOTO_PERMISSION_DENIED',
          ),
        ),
      );
    },
  );

  test('expired signed URL is refreshed once before saving', () async {
    final repository = _Repository();
    final dio = Dio();
    var attempts = 0;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (attempts++ == 0) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.badResponse,
                response: Response(requestOptions: options, statusCode: 403),
              ),
            );
          } else {
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: ResponseBody.fromBytes(_bytes, 200),
              ),
            );
          }
        },
      ),
    );
    await ChatImageGallery(downloadClient: dio).save(
      message: _image(),
      repository: repository,
      session: _scope,
      hasAccess: () => true,
    );
    expect(repository.signedRequests, 2);
    expect(calls, hasLength(1));
  });
}

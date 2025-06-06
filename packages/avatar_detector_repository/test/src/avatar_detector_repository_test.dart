import 'dart:collection';

import 'package:avatar_detector_repository/avatar_detector_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:tensorflow_models/tensorflow_models.dart';
import 'package:test/test.dart';

class _MockTensorflowModelsPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements TensorflowModelsPlatform {}

class _MockFaceLandmarksDetector extends Mock
    implements FaceLandmarksDetector {}

class _FakeEstimationConfig extends Fake implements EstimationConfig {}

class _FakeKeypoint extends Fake implements Keypoint {
  _FakeKeypoint(this.x, this.y, this.z, {this.name = ''});

  @override
  final double x;

  @override
  final double y;

  @override
  final double? z;

  @override
  final String name;
}

class _FakeFace extends Fake implements Face {
  _FakeFace({
    List<Keypoint>? keypoints,
  }) : _keypoints =
            keypoints ?? List.generate(478, (_) => _FakeKeypoint(0, 0, 0));

  final List<Keypoint> _keypoints;

  @override
  UnmodifiableListView<Keypoint> get keypoints =>
      UnmodifiableListView(_keypoints);

  @override
  BoundingBox get boundingBox => const BoundingBox(10, 10, 110, 110, 100, 100);
}

class _MockImageData extends Mock implements ImageData {}

void main() {
  group('AvatarDetectorRepository', () {
    late AvatarDetectorRepository avatarDetectorRepository;
    late FaceLandmarksDetector faceLandmarksDetector;
    late TensorflowModelsPlatform tensorflowModelsPlatform;

    setUp(() {
      tensorflowModelsPlatform = _MockTensorflowModelsPlatform();
      TensorflowModelsPlatform.instance = tensorflowModelsPlatform;
      faceLandmarksDetector = _MockFaceLandmarksDetector();
      avatarDetectorRepository = AvatarDetectorRepository();
      when(() => tensorflowModelsPlatform.loadFaceLandmark())
          .thenAnswer((_) async => faceLandmarksDetector);
    });

    setUpAll(() {
      registerFallbackValue(_FakeEstimationConfig());
    });

    test('can be instantiated', () {
      expect(AvatarDetectorRepository(), isNotNull);
    });

    group('initLandmarksModel', () {
      test('throws PreloadLandmarksModelException if any exception occurs', () {
        when(() => tensorflowModelsPlatform.loadFaceLandmark())
            .thenThrow(Exception());
        expect(
          avatarDetectorRepository.preloadLandmarksModel(),
          throwsA(isA<PreloadLandmarksModelException>()),
        );
      });

      test('completes', () {
        when(tensorflowModelsPlatform.loadFaceLandmark)
            .thenAnswer((_) async => _MockFaceLandmarksDetector());
        expect(avatarDetectorRepository.preloadLandmarksModel(), completes);
      });
    });

    group('detectAvatar', () {
      late ImageData imageData;

      setUp(() {
        imageData = _MockImageData();
        when(() => imageData.size).thenReturn(Size(1280, 720));
      });

      test(
          'calls preloadLandmarksModel if '
          'faceLandmarksDetector is not initialized yet', () async {
        when(
          () => faceLandmarksDetector.estimateFaces(
            imageData,
            estimationConfig: any(named: 'estimationConfig'),
          ),
        ).thenAnswer((_) async => <Face>[_FakeFace()]);
        await avatarDetectorRepository.detectAvatar(imageData);
        verify(() => tensorflowModelsPlatform.loadFaceLandmark()).called(1);
      });

      test('throws DetectAvatarException if estimateFaces fails', () {
        when(
          () => faceLandmarksDetector.estimateFaces(
            imageData,
            estimationConfig: any(named: 'estimationConfig'),
          ),
        ).thenThrow(Exception());
        expect(
          avatarDetectorRepository.detectAvatar(imageData),
          throwsA(isA<DetectAvatarException>()),
        );
      });

      test('returns null if estimateFaces returns empty list', () async {
        when(
          () => faceLandmarksDetector.estimateFaces(
            imageData,
            estimationConfig: any(named: 'estimationConfig'),
          ),
        ).thenAnswer((_) async => List<Face>.empty());

        await expectLater(
          avatarDetectorRepository.detectAvatar(imageData),
          completion(isNull),
        );
      });

      test("returns null if the face doesn't have enough keypoints", () async {
        when(
          () => faceLandmarksDetector.estimateFaces(
            imageData,
            estimationConfig: any(named: 'estimationConfig'),
          ),
        ).thenAnswer((_) async => <Face>[_FakeFace(keypoints: [])]);
        await expectLater(
          avatarDetectorRepository.detectAvatar(imageData),
          completion(isNull),
        );
      });

      test('returns null if the face is outside horizontal bounds', () async {
        final keypoints = List.generate(478, (_) => _FakeKeypoint(0, 0, 0));
        keypoints[0] =
            _FakeKeypoint(imageData.size.width + 1, 0, 0, name: 'faceOval');
        when(
          () => faceLandmarksDetector.estimateFaces(
            imageData,
            estimationConfig: any(named: 'estimationConfig'),
          ),
        ).thenAnswer((_) async => <Face>[_FakeFace(keypoints: keypoints)]);
        await expectLater(
          avatarDetectorRepository.detectAvatar(imageData),
          completion(isNull),
        );
      });

      test('returns null if the face is outside vertical bounds', () async {
        final keypoints = List.generate(478, (_) => _FakeKeypoint(0, 0, 0));
        keypoints[0] =
            _FakeKeypoint(0, imageData.size.height + 1, 0, name: 'faceOval');
        when(
          () => faceLandmarksDetector.estimateFaces(
            imageData,
            estimationConfig: any(named: 'estimationConfig'),
          ),
        ).thenAnswer((_) async => <Face>[_FakeFace(keypoints: keypoints)]);
        await expectLater(
          avatarDetectorRepository.detectAvatar(imageData),
          completion(isNull),
        );
      });

      test('return an Avatar', () async {
        when(
          () => faceLandmarksDetector.estimateFaces(
            imageData,
            estimationConfig: any(named: 'estimationConfig'),
          ),
        ).thenAnswer((_) async => <Face>[_FakeFace()]);
        await expectLater(
          avatarDetectorRepository.detectAvatar(imageData),
          completion(isA<Avatar>()),
        );
      });

      test('return an Avatar when called multiple times', () async {
        when(
          () => faceLandmarksDetector.estimateFaces(
            imageData,
            estimationConfig: any(named: 'estimationConfig'),
          ),
        ).thenAnswer((_) async => <Face>[_FakeFace()]);

        await expectLater(
          await avatarDetectorRepository.detectAvatar(imageData),
          isA<Avatar>(),
        );
        await expectLater(
          await avatarDetectorRepository.detectAvatar(imageData),
          isA<Avatar>(),
        );
      });
    });

    group('dispose', () {
      test('calls to dispose', () async {
        await avatarDetectorRepository.preloadLandmarksModel();
        avatarDetectorRepository.dispose();
        verify(() => faceLandmarksDetector.dispose()).called(1);
      });
    });
  });
}

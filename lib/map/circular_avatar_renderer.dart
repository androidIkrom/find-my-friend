import 'dart:typed_data';
import 'dart:ui' as ui;

class CircularAvatarRenderer {
  const CircularAvatarRenderer();

  Future<Uint8List> render(Uint8List sourceBytes, {double size = 160}) async {
    final codec = await ui.instantiateImageCodec(
      sourceBytes,
      targetWidth: size.round(),
      targetHeight: size.round(),
    );
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final radius = size / 2;
    final center = ui.Offset(radius, radius);

    final clipPath = ui.Path()
      ..addOval(ui.Rect.fromCircle(center: center, radius: radius));
    canvas.clipPath(clipPath);
    canvas.drawImage(image, ui.Offset.zero, ui.Paint());

    final borderPaint = ui.Paint()
      ..color = const ui.Color(0xFFFFFFFF)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = size * 0.06;
    canvas.drawCircle(center, radius - borderPaint.strokeWidth / 2, borderPaint);

    final picture = recorder.endRecording();
    final rendered = await picture.toImage(size.round(), size.round());
    final byteData = await rendered.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}

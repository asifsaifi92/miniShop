// Run with: dart run tool/generate_icon.dart
import 'dart:io';
import 'package:image/image.dart' as img;

void main() async {
  const size = 1024;
  final indigo = img.ColorRgba8(59, 79, 216, 255);
  final white = img.ColorRgba8(255, 255, 255, 255);
  final transparent = img.ColorRgba8(0, 0, 0, 0);

  // ── Full icon (indigo bg + white bag) ───────────────────────────
  final icon = img.Image(width: size, height: size);
  img.fill(icon, color: indigo);
  _drawBag(icon, white, indigo);

  final dir = Directory('assets/icon');
  if (!dir.existsSync()) dir.createSync(recursive: true);
  File('assets/icon/icon.png').writeAsBytesSync(img.encodePng(icon));
  stdout.writeln('  assets/icon/icon.png');

  // ── Foreground icon (transparent bg + white bag) for adaptive ───
  final fg = img.Image(width: size, height: size);
  img.fill(fg, color: transparent);
  _drawBag(fg, white, transparent);

  File('assets/icon/icon_fg.png').writeAsBytesSync(img.encodePng(fg));
  stdout.writeln('  assets/icon/icon_fg.png');

  stdout.writeln('Done!');
}

void _drawBag(img.Image canvas, img.Color bagColor, img.Color holeColor) {
  // Bag body: 600 × 440 px, vertically centered slightly below midpoint
  const x1 = 212, y1 = 420, x2 = 812, y2 = 860;
  img.fillRect(canvas, x1: x1, y1: y1, x2: x2, y2: y2, color: bagColor);

  // Rounded corners on bag body using circles at each corner
  const r = 52;
  img.fillCircle(canvas, x: x1 + r, y: y1 + r, radius: r, color: bagColor);
  img.fillCircle(canvas, x: x2 - r, y: y1 + r, radius: r, color: bagColor);
  img.fillCircle(canvas, x: x1 + r, y: y2 - r, radius: r, color: bagColor);
  img.fillCircle(canvas, x: x2 - r, y: y2 - r, radius: r, color: bagColor);

  // Remove corner fill artifacts by re-filling the inner rect
  img.fillRect(canvas,
      x1: x1 + r, y1: y1, x2: x2 - r, y2: y2, color: bagColor);
  img.fillRect(canvas,
      x1: x1, y1: y1 + r, x2: x2, y2: y2 - r, color: bagColor);

  // Handle holes: two indigo circles straddling the bag top edge
  // Center at y=400 (20 px above bag top), radius=80
  // Creates a 100 px arch visible above bag + 60 px hole into bag
  img.fillCircle(canvas, x: 362, y: 400, radius: 82, color: holeColor);
  img.fillCircle(canvas, x: 662, y: 400, radius: 82, color: holeColor);
}

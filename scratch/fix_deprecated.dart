
import 'dart:io';

void main() {
  final dir = Directory('lib');
  if (!dir.existsSync()) return;

  dir.listSync(recursive: true).forEach((entity) {
    if (entity is File && entity.path.endsWith('.dart')) {
      String content = entity.readAsStringSync();
      
      // Fix withOpacity
      final withOpacityRegex = RegExp(r'\.withOpacity\((.*?)\)');
      if (content.contains(withOpacityRegex)) {
        print('Fixing withOpacity in ${entity.path}');
        content = content.replaceAllMapped(withOpacityRegex, (match) {
          return '.withValues(alpha: ${match.group(1)})';
        });
      }

      // Fix onPopInvoked
      if (content.contains('onPopInvoked:')) {
         print('Fixing onPopInvoked in ${entity.path}');
         content = content.replaceAll('onPopInvoked: (didPop) {', 'onPopInvokedWithResult: (didPop, result) {');
         content = content.replaceAll('onPopInvoked: (didPop) async {', 'onPopInvokedWithResult: (didPop, result) async {');
      }

      entity.writeAsStringSync(content);
    }
  });
}

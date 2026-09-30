import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('photo recipe workflow uses the real together_recipe schema and conservative extraction rules', () {
    final prompt = File('lib/features/recipes/together_chatgpt_prompt.dart').readAsStringSync();
    final page = File('lib/features/recipes/add_recipe_page.dart').readAsStringSync();
    final importer = File('lib/data/models/together_recipe_importer.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(prompt, contains('buildPhotoImportPrompt'));
    expect(prompt, contains('das angehängte Foto eines Rezepts'));
    expect(prompt, contains('Erfinde keine Zutaten'));
    expect(prompt, contains('"format": "together_recipe"'));
    expect(prompt, contains('"version": 1'));
    expect(prompt, contains('"is_qualitative": false'));
    expect(page, contains('PhotoRecipeChatGptPage'));
    expect(page, contains('ImageSource.camera'));
    expect(page, contains('ImageSource.gallery'));
    expect(page, contains('SharePlus.instance.share'));
    expect(page, contains('TogetherChatGptPrompt.buildPhotoImportPrompt()'));
    expect(importer, contains('isQualitative'));
    expect(pubspec, contains('image_picker:'));
    expect(pubspec, contains('share_plus:'));
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final sources = <String, String>{
    for (final file in Directory(
      'lib',
    ).listSync(recursive: true).whereType<File>())
      if (file.path.endsWith('.dart'))
        file.path.replaceAll('\\', '/'): file.readAsStringSync(),
  };
  final directives = RegExp(
    r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
    multiLine: true,
  );

  test('source files are independent Dart libraries without parts', () {
    final violations = sources.entries
        .where(
          (entry) =>
              RegExp(r'^\s*part\s+', multiLine: true).hasMatch(entry.value),
        )
        .map((entry) => entry.key);
    expect(violations, isEmpty);
    expect(sources.keys.where((path) => path.contains('/parts/')), isEmpty);
  });

  test('each file owns at most one widget, including widget subclasses', () {
    final classes = RegExp(r'\bclass\s+(\w+)\s+extends\s+(\w+)');
    final bases = <String, String>{
      for (final source in sources.values)
        for (final match in classes.allMatches(source)) match[1]!: match[2]!,
    };
    const widgetBases = {
      'Widget',
      'StatelessWidget',
      'StatefulWidget',
      'InheritedWidget',
      'InheritedNotifier',
      'InheritedModel',
      'ProxyWidget',
      'RenderObjectWidget',
      'SingleChildRenderObjectWidget',
      'MultiChildRenderObjectWidget',
      'LeafRenderObjectWidget',
    };
    bool isWidget(String name) {
      final visited = <String>{};
      while (visited.add(name)) {
        if (widgetBases.contains(name)) return true;
        final parent = bases[name];
        if (parent == null) return false;
        name = parent;
      }
      return false;
    }

    for (final entry in sources.entries) {
      final widgets = classes
          .allMatches(entry.value)
          .where((match) => isWidget(match[1]!))
          .map((match) => match[1]!)
          .toList();
      expect(
        widgets.length,
        lessThanOrEqualTo(1),
        reason: '${entry.key}: $widgets',
      );
    }
  });

  test('domain stays independent of UI and infrastructure', () {
    const frameworkPackages = {
      'flutter',
      'flutter_bloc',
      'dio',
      'supabase_flutter',
      'shared_preferences',
      'sembast',
      'image_picker',
      'geolocator',
      'just_audio',
      'record',
      'get_it',
      'go_router',
      'path_provider',
    };
    for (final entry in sources.entries.where(
      (e) => e.key.contains('/domain/'),
    )) {
      for (final directive in directives.allMatches(entry.value)) {
        final dependency = directive[1]!;
        expect(
          dependency.contains('/data/') ||
              dependency.contains('/presentation/') ||
              dependency.contains('/application/'),
          isFalse,
          reason: '${entry.key} depends on $dependency',
        );
        if (dependency.startsWith('package:')) {
          final package = dependency
              .substring('package:'.length)
              .split('/')
              .first;
          expect(
            frameworkPackages,
            isNot(contains(package)),
            reason: '${entry.key} depends on $dependency',
          );
        }
      }
    }
  });

  test('presentation uses contracts rather than data implementations', () {
    for (final entry in sources.entries.where(
      (e) => e.key.contains('/presentation/'),
    )) {
      for (final directive in directives.allMatches(entry.value)) {
        expect(
          directive[1],
          isNot(contains('/data/')),
          reason: '${entry.key} depends on ${directive[1]}',
        );
      }
    }
  });
}

#!/usr/bin/env dart
/// Static security linter for DeltaBooks Flutter frontend.
///
/// Checks every .dart file under lib/ for patterns that indicate user input
/// is being passed to network or rendering APIs without proper sanitisation.
///
/// Run:   dart run tools/check_input_safety.dart
/// Exit:  0 = clean, 1 = violations found
///
/// Add to git pre-commit:
///   echo 'dart run tools/check_input_safety.dart' >> .git/hooks/pre-commit
///   chmod +x .git/hooks/pre-commit

import 'dart:io';

// ---------------------------------------------------------------------------
// Rule definitions
// ---------------------------------------------------------------------------

class Violation {
  final String file;
  final int line;
  final String rule;
  final String detail;
  final String? fix;

  Violation(this.file, this.line, this.rule, this.detail, {this.fix});

  @override
  String toString() {
    final loc = '$file:$line';
    final fixNote = fix != null ? '\n     Fix: $fix' : '';
    return '  [$rule] $loc\n     $detail$fixNote';
  }
}

// ---------------------------------------------------------------------------
// Patterns
// ---------------------------------------------------------------------------

/// Matches an interpolation that is NOT a plain integer ID.
/// Integer IDs look like: $libraryId, $bookId, $userId, $memberId, ${someId}
/// Anything else (email, query, name, search term, etc.) is treated as a
/// potential string value that must be URL-encoded.
final _idPattern = RegExp(
  r'\$\{?[a-zA-Z_][a-zA-Z0-9_]*[Ii][dD]\}?',
);

/// Finds apiService.get('…?…$var') where $var is NOT an integer ID.
/// Also catches the long-form _apiService.get("…?…$var").
final _unsafeGetParam = RegExp(
  r'''_?apiService\.get\(['"]/[^'"]*\?[^'"]*\$(?!\{?[a-zA-Z_]*[Ii][dD]\}?)''',
);

/// Also catches any raw string interpolation in a URL query-string position.
/// Pattern: anything that looks like `?word=$nonId` or `&word=$nonId`.
final _unsafeQueryInterpolation = RegExp(
  r'''[?&][a-zA-Z_][a-zA-Z0-9_]*=\$(?!\{?[a-zA-Z_]*[Ii][dD]\}?)[a-zA-Z_]''',
);

/// TextFormField missing a validator: argument.
final _textFormFieldNoValidator = RegExp(
  r'TextFormField\s*\(',
);

/// Flag use of getWithParams-equivalent being bypassed by .get with a query string.
/// More general: flag any `.get(` call where the argument string contains `?` and `$`.
final _getWithQueryAndInterpolation = RegExp(
  r'''\.get\(\s*['"][^'"]*\?[^'"]*\$[a-zA-Z_]''',
);

// ---------------------------------------------------------------------------
// Scanner
// ---------------------------------------------------------------------------

List<Violation> checkFile(File file) {
  final violations = <Violation>[];
  final lines = file.readAsLinesSync();
  final path = file.path.replaceFirst(RegExp(r'^.*/lib/'), 'lib/');

  bool inTextFormField = false;
  bool hasValidator = false;
  int textFormFieldLine = 0;
  int braceDepth = 0;

  for (var i = 0; i < lines.length; i++) {
    final lineNum = i + 1;
    final line = lines[i];
    final trimmed = line.trim();

    // Skip comment lines
    if (trimmed.startsWith('//') || trimmed.startsWith('*')) continue;

    // -----------------------------------------------------------------------
    // Rule 1: .get() with a user string in a query parameter
    // -----------------------------------------------------------------------
    if (_getWithQueryAndInterpolation.hasMatch(line)) {
      // Exclude interpolations that are purely integer IDs
      final paramSection = line.substring(line.indexOf('?'));
      final interpolations = RegExp(r'\$\{?([a-zA-Z_][a-zA-Z0-9_]*)\}?')
          .allMatches(paramSection)
          .where((m) => !_idPattern.hasMatch('\$${m.group(1)}'))
          .toList();

      if (interpolations.isNotEmpty) {
        final varName = interpolations.first.group(1);
        violations.add(Violation(
          path,
          lineNum,
          'URL_PARAM_INJECTION',
          'Variable "\$$varName" is raw-interpolated into a URL query string.',
          fix:
              'Use _apiService.getWithParams(path, {\'key\': $varName}) instead '
              '— it percent-encodes values automatically.',
        ));
      }
    }

    // -----------------------------------------------------------------------
    // Rule 2: TextFormField without validator
    // -----------------------------------------------------------------------
    // A comment `// input-safety: ok` on the same line as TextFormField suppresses
    // MISSING_VALIDATOR for that field (use for intentionally optional fields).
    final suppressed = line.contains('// input-safety: ok');

    if (_textFormFieldNoValidator.hasMatch(line) && !inTextFormField && !suppressed) {
      inTextFormField = true;
      hasValidator = false;
      textFormFieldLine = lineNum;
      braceDepth = 0;
    }

    if (inTextFormField) {
      braceDepth += '('.allMatches(line).length;
      braceDepth -= ')'.allMatches(line).length;

      if (line.contains('validator:')) hasValidator = true;

      if (braceDepth <= 0 && lineNum > textFormFieldLine) {
        if (!hasValidator) {
          violations.add(Violation(
            path,
            textFormFieldLine,
            'MISSING_VALIDATOR',
            'TextFormField has no validator: callback.',
            fix: 'Add a validator that rejects empty/invalid input before '
                'it reaches the API.',
          ));
        }
        inTextFormField = false;
      }
    }

    // -----------------------------------------------------------------------
    // Rule 3: innerHTML / innerHtml / eval — relevant for Flutter Web
    // -----------------------------------------------------------------------
    if (RegExp(r'\.(innerHtml|innerHTML|setInnerHtml)\s*=').hasMatch(line)) {
      violations.add(Violation(
        path,
        lineNum,
        'XSS_HTML_INJECTION',
        'Direct assignment to innerHTML/innerHtml detected.',
        fix: 'Never insert user-controlled content as raw HTML. '
            'Use Flutter Text widgets or sanitise first.',
      ));
    }

    // -----------------------------------------------------------------------
    // Rule 4: js.eval / js.context.callMethod with a string variable
    // -----------------------------------------------------------------------
    if (RegExp(r'js\.(eval|context\.callMethod)\s*\(').hasMatch(line) &&
        line.contains(r'$')) {
      violations.add(Violation(
        path,
        lineNum,
        'JS_INJECTION',
        'JavaScript interop call with interpolated string.',
        fix: 'Never build JS code from user input. Pass data as typed arguments.',
      ));
    }

    // -----------------------------------------------------------------------
    // Rule 5: Uri.parse on a variable (potential open-redirect / SSRF)
    // -----------------------------------------------------------------------
    if (RegExp(r'Uri\.parse\s*\(\s*[a-zA-Z_]').hasMatch(line) &&
        !line.contains("'\$baseUrl") &&
        !line.contains('"\$baseUrl') &&
        !line.contains("'http") &&
        !line.contains('"http') &&
        !line.contains('//') // comment
        ) {
      // Only flag if the variable name looks like it could come from user input
      final match = RegExp(r'Uri\.parse\s*\(\s*([a-zA-Z_][a-zA-Z0-9_]*)')
          .firstMatch(line);
      if (match != null) {
        final varName = match.group(1)!;
        final suspiciousNames = RegExp(
          r'(url|link|href|redirect|path|uri|address)',
          caseSensitive: false,
        );
        if (suspiciousNames.hasMatch(varName)) {
          violations.add(Violation(
            path,
            lineNum,
            'OPEN_REDIRECT',
            'Uri.parse("\$$varName") — ensure this URL is not user-controlled '
                'or validate it is an allowed host before use.',
          ));
        }
      }
    }
  }

  return violations;
}

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

void main(List<String> args) {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    stderr.writeln('Run this script from the frontend/ directory.');
    exit(2);
  }

  final dartFiles = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  final allViolations = <Violation>[];
  for (final file in dartFiles) {
    allViolations.addAll(checkFile(file));
  }

  if (allViolations.isEmpty) {
    stdout.writeln('check_input_safety: no violations found (${dartFiles.length} files scanned).');
    exit(0);
  }

  stderr.writeln(
    '\ncheck_input_safety: ${allViolations.length} violation(s) found:\n',
  );
  for (final v in allViolations) {
    stderr.writeln(v);
    stderr.writeln();
  }
  exit(1);
}

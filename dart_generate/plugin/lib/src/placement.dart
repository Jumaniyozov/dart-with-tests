import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:generate_core/generate_core.dart';

// `format` takes a range in original-file coordinates, and it replaces the
// range with the formatted text of the range. A range that starts or ends in
// whitespace loses that whitespace: the formatted text starts and ends at a
// token. `format` throws when its range covers only part of an earlier edit.
// A replaced member and a new member next to it share a token, so their two
// ranges would overlap. The rule is one format per action. `writeMembers`
// adds each replacement, insertion and deletion as a plain edit, and then
// formats the class body from `{` to `}`. `insertAfter` and `insertAtStart`
// add one member in one edit, so their range runs from the token before the
// insertion to the token after it.

/// Writes [members] into [cls], and deletes [delete]. An existing member with
/// the same name is replaced in place. `fromJson` goes after the last
/// constructor. The rest go at the end of the body, after any comment before
/// `}`. Returns whether any member other than `_unset` already existed.
bool writeMembers(
  DartFileEditBuilder builder,
  ClassDeclaration cls,
  List<Member> members, {
  List<ClassMember> delete = const [],
}) {
  var replaced = false;
  final atStart = <String>[];
  final atEnd = <String>[];
  for (final member in members) {
    final existing = findMember(cls, member.name);
    if (existing != null) {
      // `_unset` is the same text every time. Keep the one that is there. It
      // is a helper, so it does not make the action a "Regenerate".
      if (member.name != '_unset') {
        replaced = true;
        builder.addSimpleReplacement(_memberRange(existing), member.code);
      }
    } else if (member.name == 'fromJson') {
      final last = _lastConstructor(cls);
      if (last == null) {
        atStart.add(member.code);
      } else if (last == cls.body.members.last) {
        // The end of the body is right after the constructor: one edit.
        atEnd.insert(0, member.code);
      } else {
        // A member follows, so a blank line goes after fromJson too.
        builder.addSimpleInsertion(
          afterLine(cls, last.endToken),
          '\n\n${member.code}\n',
        );
      }
    } else {
      atEnd.add(member.code);
    }
  }
  for (final member in delete) {
    builder.deleteClassMember(member);
  }
  // A `;` body is one token, and a body with no members has one gap between
  // its braces. Either way, the start is the end, so it takes one edit.
  if (cls.body case EmptyClassBody() || BlockClassBody(members: [])) {
    atEnd.insertAll(0, atStart);
    atStart.clear();
  }
  switch (cls.body) {
    case EmptyClassBody(:final semicolon):
      if (atEnd.isNotEmpty) {
        _replaceSemicolon(builder, semicolon, atEnd.join('\n\n'));
      }
    case BlockClassBody(:final leftBracket, :final rightBracket):
      if (atStart.isNotEmpty) {
        builder.addSimpleInsertion(
          afterLine(cls, leftBracket),
          '\n${atStart.join('\n\n')}\n\n',
        );
      }
      if (atEnd.isNotEmpty) {
        final end = _bodyEnd(cls, rightBracket);
        // Right after `{`, the members need no blank line before them.
        final gap = end == leftBracket.end ? '\n' : '\n\n';
        builder.addSimpleInsertion(end, '$gap${atEnd.join('\n\n')}');
      }
      // One format over the whole body: no two ranges can touch.
      builder.format(
        SourceRange(leftBracket.offset, rightBracket.end - leftBracket.offset),
      );
  }
  return replaced;
}

/// The offset after the last member of [cls] and after every comment before
/// [rightBracket].
int _bodyEnd(ClassDeclaration cls, Token rightBracket) {
  var end = afterLine(cls, rightBracket.previous!);
  for (Token? c = rightBracket.precedingComments; c != null; c = c.next) {
    if (c.end > end) end = c.end;
  }
  return end;
}

ClassMember? _lastConstructor(ClassDeclaration cls) => cls.body.members
    .where((m) => m is ConstructorDeclaration || m is PrimaryConstructorBody)
    .lastOrNull;

/// The member of [cls] named [name], or `null`.
ClassMember? findMember(ClassDeclaration cls, String name) {
  for (final member in cls.body.members) {
    final found = switch (member) {
      MethodDeclaration(name: final token) => token.lexeme == name,
      ConstructorDeclaration(name: final token?) => token.lexeme == name,
      FieldDeclaration(:final fields) => fields.variables.any(
        (v) => v.name.lexeme == name,
      ),
      _ => false,
    };
    if (found) return member;
  }
  return null;
}

/// The range that replaces [member]: from its first annotation to its end,
/// so its doc comment stays.
SourceRange _memberRange(ClassMember member) {
  final start = member.metadata.isEmpty
      ? member.firstTokenAfterCommentAndMetadata.offset
      : member.metadata.first.offset;
  return SourceRange(start, member.end - start);
}

/// Adds [code] at the start of the body of [cls].
void insertAtStart(
  DartFileEditBuilder builder,
  ClassDeclaration cls,
  String code,
) {
  switch (cls.body) {
    case BlockClassBody(:final leftBracket, :final members):
      final gap = members.isEmpty ? '\n' : '\n\n';
      _insertAfter(builder, cls, leftBracket, '\n$code$gap');
    case EmptyClassBody(:final semicolon):
      _replaceSemicolon(builder, semicolon, code);
  }
}

/// Adds [code] after [node], after one blank line. When more follows before
/// the closing `}`, a blank line goes after [code] too.
void insertAfter(DartFileEditBuilder builder, AstNode node, String code) {
  final end = node.endToken;
  final more = _moreFollows(node, end) ? '\n' : '';
  _insertAfter(builder, node, end, '\n\n$code$more');
}

/// Whether a member, or a comment on a later line, follows [token] before the
/// closing `}`.
bool _moreFollows(AstNode node, Token token) {
  final next = token.next!;
  if (next.type != TokenType.CLOSE_CURLY_BRACKET) return true;
  final end = afterLine(node, token);
  for (Token? c = next.precedingComments; c != null; c = c.next) {
    if (c.offset >= end) return true;
  }
  return false;
}

/// Inserts [text] after [token] and any comment that ends its line, and
/// formats from [token] to the next token.
void _insertAfter(
  DartFileEditBuilder builder,
  AstNode node,
  Token token,
  String text,
) {
  builder.addSimpleInsertion(afterLine(node, token), text);
  final next = token.next!;
  builder.format(SourceRange(token.offset, next.end - token.offset));
}

/// The offset after [token] and any comment that ends its line. A doc comment
/// on that line documents the next declaration, so it is not part of the
/// line. [node] is any node of the unit, for line numbers.
int afterLine(AstNode node, Token token) {
  final lines = (node.root as CompilationUnit).lineInfo;
  final line = lines.getLocation(token.end).lineNumber;
  var offset = token.end;
  for (Token? c = token.next!.precedingComments; c != null; c = c.next) {
    if (lines.getLocation(c.offset).lineNumber != line) break;
    if (c.lexeme.startsWith('///') || c.lexeme.startsWith('/**')) break;
    offset = c.end;
  }
  return offset;
}

/// Turns a `;` body into `{ code }`.
void _replaceSemicolon(
  DartFileEditBuilder builder,
  Token semicolon,
  String code,
) {
  builder.addSimpleReplacement(
    SourceRange(semicolon.offset, semicolon.length),
    ' {\n$code\n}',
  );
  final start = semicolon.previous!.offset;
  builder.format(SourceRange(start, semicolon.end - start));
}

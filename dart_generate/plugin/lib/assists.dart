/// The assists and the class reader, for the VS Code helper.
///
/// The analysis server loads `main.dart`, not this file.
library;

export 'src/assist.dart' show GenerateAssist, fieldNames;
export 'src/assists.dart';
export 'src/placement.dart' show findMember;
export 'src/read_class.dart' show readClass;

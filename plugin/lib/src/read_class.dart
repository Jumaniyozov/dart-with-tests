import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:generate_core/generate_core.dart';

/// Reads a resolved class into the model that the generators use.
///
/// Elements give the meaning. Positions come from the syntax tree elsewhere.
ClassModel readClass(ClassElement element, TypeSystem types) {
  final fieldTypes = <String, DartType>{};
  final fields = <FieldModel>[];

  void add(String name, DartType type, FieldElement? field) {
    if (fieldTypes.containsKey(name)) return;
    fieldTypes[name] = type;
    fields.add(
      FieldModel(
        name,
        readType(type, types),
        isFinal: field?.isFinal ?? true,
        isLate: field?.isLate ?? false,
        hasInitializer: field?.hasInitializer ?? false,
      ),
    );
  }

  // Header order first, so inherited fields keep their place.
  for (final p in element.primaryConstructor?.formalParameters ?? const []) {
    switch (p) {
      case SuperFormalParameterElement():
        if (_inheritedField(p) case final field?) {
          add(p.displayName, p.type, field);
        }
      case FieldFormalParameterElement(:final field?):
        add(field.displayName, field.type, field);
    }
  }
  // A classic constructor has no header, so its inherited fields go first, in
  // the order that the constructors take them.
  for (final c in element.constructors) {
    for (final p
        in c.formalParameters.whereType<SuperFormalParameterElement>()) {
      if (_inheritedField(p) case final field?) {
        add(p.displayName, p.type, field);
      }
    }
  }
  for (final f in element.fields) {
    if (f.isStatic || f.isAbstract || f.isExternal) continue;
    if (!f.isOriginDeclaration && !f.isOriginDeclaringFormalParameter) continue;
    add(f.displayName, f.type, f);
  }

  final constructors = [
    for (final c in element.constructors)
      ConstructorModel(
        c.name == 'new'
            ? element.displayName
            : '${element.displayName}.${c.name}',
        [
          for (final p in c.formalParameters)
            ParamModel(
              p.displayName,
              readType(p.type, types),
              isNamed: p.isNamed,
              isRequired: p.isRequired,
              defaultValue: p.defaultValueCode,
              fitsField: switch (fieldTypes[p.displayName]) {
                final type? => types.isAssignableTo(type, p.type),
                null => false,
              },
            ),
        ],
        isPublic: c.isPublic,
        isCallable: c.isFactory || !element.isAbstract,
      ),
  ];
  return ClassModel(
    element.thisType.getDisplayString(),
    fields,
    chooseBuilder(fields, constructors),
  );
}

/// The field that a `super.` parameter sets, following `super.` chains.
FieldElement? _inheritedField(SuperFormalParameterElement parameter) {
  FormalParameterElement? p = parameter;
  while (p is SuperFormalParameterElement) {
    p = p.superConstructorParameter;
  }
  return p is FieldFormalParameterElement ? p.field : null;
}

/// Sorts [type] into the kinds that the JSON rules know.
TypeModel readType(DartType type, TypeSystem types) {
  final code = type.getDisplayString();
  final isNullable = types.isPotentiallyNullable(type);
  if (type is DynamicType) return PassthroughType(code, isNullable: true);
  if (type is TypeParameterType) {
    return TypeParameterModel(code, isNullable: isNullable);
  }
  if (type is! InterfaceType) return OtherType(code, isNullable: isNullable);
  if (type.isDartCoreInt ||
      type.isDartCoreString ||
      type.isDartCoreBool ||
      type.isDartCoreNum) {
    return PrimitiveType(code, isNullable: isNullable);
  }
  if (type.isDartCoreDouble) return DoubleType(code, isNullable: isNullable);
  if (type.isDartCoreObject) {
    return PassthroughType(code, isNullable: isNullable);
  }
  if (type.element is EnumElement) {
    return EnumType(code, isNullable: isNullable);
  }
  if (type.element.displayName == 'DateTime' &&
      type.element.library.isDartCore) {
    return DateTimeType(code, isNullable: isNullable);
  }
  final arguments = [for (final a in type.typeArguments) readType(a, types)];
  if (type.isDartCoreList) {
    return ListType(code, arguments.single, isNullable: isNullable);
  }
  if (type.isDartCoreSet) {
    return SetType(code, arguments.single, isNullable: isNullable);
  }
  if (type.isDartCoreMap) {
    return MapType(code, arguments[0], arguments[1], isNullable: isNullable);
  }
  return OtherType(code, isNullable: isNullable);
}

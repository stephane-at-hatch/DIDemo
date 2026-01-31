/// TODO: Description of what the macro does
/// 
/// Example usage:
/// ```swift
/// @Copyable
/// struct MyType { }
/// ```
@attached(member, names: named(copy))
public macro Copyable() = #externalMacro(
    module: "CopyableMacroImplementation",
    type: "CopyableMacro"
)

// MARK: - Basic signatures (no local)

@attached(member, names: arbitrary)
public macro DependencyRequirements() =
    #externalMacro(
        module: "DependencyRequirementsMacroImplementation",
        type: "DependencyRequirementsMacro"
    )

@attached(member, names: arbitrary)
public macro DependencyRequirements(_ requirements: [Any]) =
    #externalMacro(
        module: "DependencyRequirementsMacroImplementation",
        type: "DependencyRequirementsMacro"
    )

@attached(member, names: arbitrary)
public macro DependencyRequirements(_ requirements: [Any], mainActor: [Any]) =
    #externalMacro(
        module: "DependencyRequirementsMacroImplementation",
        type: "DependencyRequirementsMacro"
    )

@attached(member, names: arbitrary)
public macro DependencyRequirements(_ requirements: [Any], inputs: [Any]) =
    #externalMacro(
        module: "DependencyRequirementsMacroImplementation",
        type: "DependencyRequirementsMacro"
    )

@attached(member, names: arbitrary)
public macro DependencyRequirements(_ requirements: [Any], mainActor: [Any], inputs: [Any]) =
    #externalMacro(
        module: "DependencyRequirementsMacroImplementation",
        type: "DependencyRequirementsMacro"
    )

// MARK: - With local (no localMainActor)

@attached(member, names: arbitrary)
public macro DependencyRequirements(_ requirements: [Any], local: [Any]) =
    #externalMacro(
        module: "DependencyRequirementsMacroImplementation",
        type: "DependencyRequirementsMacro"
    )

@attached(member, names: arbitrary)
public macro DependencyRequirements(_ requirements: [Any], mainActor: [Any], local: [Any]) =
    #externalMacro(
        module: "DependencyRequirementsMacroImplementation",
        type: "DependencyRequirementsMacro"
    )

@attached(member, names: arbitrary)
public macro DependencyRequirements(_ requirements: [Any], local: [Any], inputs: [Any]) =
    #externalMacro(
        module: "DependencyRequirementsMacroImplementation",
        type: "DependencyRequirementsMacro"
    )

@attached(member, names: arbitrary)
public macro DependencyRequirements(_ requirements: [Any], mainActor: [Any], local: [Any], inputs: [Any]) =
    #externalMacro(
        module: "DependencyRequirementsMacroImplementation",
        type: "DependencyRequirementsMacro"
    )

// MARK: - With localMainActor (no local)

@attached(member, names: arbitrary)
public macro DependencyRequirements(_ requirements: [Any], localMainActor: [Any]) =
    #externalMacro(
        module: "DependencyRequirementsMacroImplementation",
        type: "DependencyRequirementsMacro"
    )

@attached(member, names: arbitrary)
public macro DependencyRequirements(_ requirements: [Any], mainActor: [Any], localMainActor: [Any]) =
    #externalMacro(
        module: "DependencyRequirementsMacroImplementation",
        type: "DependencyRequirementsMacro"
    )

@attached(member, names: arbitrary)
public macro DependencyRequirements(_ requirements: [Any], localMainActor: [Any], inputs: [Any]) =
    #externalMacro(
        module: "DependencyRequirementsMacroImplementation",
        type: "DependencyRequirementsMacro"
    )

@attached(member, names: arbitrary)
public macro DependencyRequirements(_ requirements: [Any], mainActor: [Any], localMainActor: [Any], inputs: [Any]) =
    #externalMacro(
        module: "DependencyRequirementsMacroImplementation",
        type: "DependencyRequirementsMacro"
    )

// MARK: - With both local and localMainActor

@attached(member, names: arbitrary)
public macro DependencyRequirements(_ requirements: [Any], local: [Any], localMainActor: [Any]) =
    #externalMacro(
        module: "DependencyRequirementsMacroImplementation",
        type: "DependencyRequirementsMacro"
    )

@attached(member, names: arbitrary)
public macro DependencyRequirements(_ requirements: [Any], mainActor: [Any], local: [Any], localMainActor: [Any]) =
    #externalMacro(
        module: "DependencyRequirementsMacroImplementation",
        type: "DependencyRequirementsMacro"
    )

@attached(member, names: arbitrary)
public macro DependencyRequirements(_ requirements: [Any], local: [Any], localMainActor: [Any], inputs: [Any]) =
    #externalMacro(
        module: "DependencyRequirementsMacroImplementation",
        type: "DependencyRequirementsMacro"
    )

@attached(member, names: arbitrary)
public macro DependencyRequirements(
    _ requirements: [Any],
    mainActor: [Any],
    local: [Any],
    localMainActor: [Any],
    inputs: [Any]
) =
    #externalMacro(
        module: "DependencyRequirementsMacroImplementation",
        type: "DependencyRequirementsMacro"
    )

// MARK: - Labeled-only (no unlabeled requirements)

// Single labeled parameter

@attached(member, names: arbitrary)
public macro DependencyRequirements(mainActor: [Any]) =
    #externalMacro(
        module: "DependencyRequirementsMacroImplementation",
        type: "DependencyRequirementsMacro"
    )

@attached(member, names: arbitrary)
public macro DependencyRequirements(local: [Any]) =
    #externalMacro(
        module: "DependencyRequirementsMacroImplementation",
        type: "DependencyRequirementsMacro"
    )

@attached(member, names: arbitrary)
public macro DependencyRequirements(localMainActor: [Any]) =
    #externalMacro(
        module: "DependencyRequirementsMacroImplementation",
        type: "DependencyRequirementsMacro"
    )

@attached(member, names: arbitrary)
public macro DependencyRequirements(inputs: [Any]) =
    #externalMacro(
        module: "DependencyRequirementsMacroImplementation",
        type: "DependencyRequirementsMacro"
    )

// Two labeled parameters

@attached(member, names: arbitrary)
public macro DependencyRequirements(mainActor: [Any], local: [Any]) =
    #externalMacro(
        module: "DependencyRequirementsMacroImplementation",
        type: "DependencyRequirementsMacro"
    )

@attached(member, names: arbitrary)
public macro DependencyRequirements(mainActor: [Any], localMainActor: [Any]) =
    #externalMacro(
        module: "DependencyRequirementsMacroImplementation",
        type: "DependencyRequirementsMacro"
    )

@attached(member, names: arbitrary)
public macro DependencyRequirements(mainActor: [Any], inputs: [Any]) =
    #externalMacro(
        module: "DependencyRequirementsMacroImplementation",
        type: "DependencyRequirementsMacro"
    )

@attached(member, names: arbitrary)
public macro DependencyRequirements(local: [Any], localMainActor: [Any]) =
    #externalMacro(
        module: "DependencyRequirementsMacroImplementation",
        type: "DependencyRequirementsMacro"
    )

@attached(member, names: arbitrary)
public macro DependencyRequirements(local: [Any], inputs: [Any]) =
    #externalMacro(
        module: "DependencyRequirementsMacroImplementation",
        type: "DependencyRequirementsMacro"
    )

@attached(member, names: arbitrary)
public macro DependencyRequirements(localMainActor: [Any], inputs: [Any]) =
    #externalMacro(
        module: "DependencyRequirementsMacroImplementation",
        type: "DependencyRequirementsMacro"
    )

// Three labeled parameters

@attached(member, names: arbitrary)
public macro DependencyRequirements(mainActor: [Any], local: [Any], localMainActor: [Any]) =
    #externalMacro(
        module: "DependencyRequirementsMacroImplementation",
        type: "DependencyRequirementsMacro"
    )

@attached(member, names: arbitrary)
public macro DependencyRequirements(mainActor: [Any], local: [Any], inputs: [Any]) =
    #externalMacro(
        module: "DependencyRequirementsMacroImplementation",
        type: "DependencyRequirementsMacro"
    )

@attached(member, names: arbitrary)
public macro DependencyRequirements(mainActor: [Any], localMainActor: [Any], inputs: [Any]) =
    #externalMacro(
        module: "DependencyRequirementsMacroImplementation",
        type: "DependencyRequirementsMacro"
    )

@attached(member, names: arbitrary)
public macro DependencyRequirements(local: [Any], localMainActor: [Any], inputs: [Any]) =
    #externalMacro(
        module: "DependencyRequirementsMacroImplementation",
        type: "DependencyRequirementsMacro"
    )

// Four labeled parameters

@attached(member, names: arbitrary)
public macro DependencyRequirements(
    mainActor: [Any],
    local: [Any],
    localMainActor: [Any],
    inputs: [Any]
) =
    #externalMacro(
        module: "DependencyRequirementsMacroImplementation",
        type: "DependencyRequirementsMacro"
    )

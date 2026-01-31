#!/bin/bash

#
# Module Scaffolding Generator
# 
# This script generates the boilerplate structure for iOS modules
# following the established architectural patterns.
#
# Supports five module types:
#   - Client: Dependency/service with protocol interface and mock
#   - Screen: Feature UI with ViewModel and Views (DreamState pattern)
#   - Coordinator: Navigation flow controller managing multiple screens
#   - Utility: General utility without abstracted interface
#   - Macro: Swift Macro for code generation
#
# Usage:
#   ./generate-module-scaffolding.sh
#
# Version: 1.0
# Based on: module_creation/SKILL.md
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Print functions
print_header() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_step() { echo -e "${CYAN}➤ $1${NC}"; }
print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }
print_info() { echo -e "  $1"; }

# Validate module name (PascalCase)
validate_module_name() {
    local name=$1
    if [[ ! "$name" =~ ^[A-Z][a-zA-Z0-9]*$ ]]; then
        print_error "Module name must be PascalCase (e.g., Analytics, UserProfile)"
        exit 1
    fi
}

# Prompt for yes/no with default
prompt_yes_no() {
    local prompt=$1
    local default=${2:-y}
    local response
    
    if [[ "$default" == "y" ]]; then
        read -p "$prompt [Y/n]: " response
        response=${response:-y}
    else
        read -p "$prompt [y/N]: " response
        response=${response:-n}
    fi
    
    [[ "$response" =~ ^[Yy] ]]
}

# Detect modules root path
detect_modules_path() {
    # Try to find the Modules directory
    local current_dir=$(pwd)
    
    # Check if we're in or near a project with Modules directory
    if [[ -d "$current_dir/Modules" ]]; then
        echo "$current_dir/Modules"
    elif [[ -d "$current_dir/../Modules" ]]; then
        echo "$(cd "$current_dir/.." && pwd)/Modules"
    elif [[ -d "$current_dir/../../Modules" ]]; then
        echo "$(cd "$current_dir/../.." && pwd)/Modules"
    else
        # Default to AppShell location
        echo "/Users/stephanemagne/Source/Projects/AppShell/Modules"
    fi
}

#
# MAIN SCRIPT
#

print_header "Module Scaffolding Generator"

# Phase 1: Select Module Type
print_header "Phase 1: Select Module Type"

echo -e "${CYAN}What type of module do you want to create?${NC}"
echo ""
echo -e "  ${MAGENTA}1)${NC} Client      - Dependency/service with protocol interface and mock"
echo -e "                  (e.g., Analytics, Auth, Storage, NetworkClient)"
echo ""
echo -e "  ${MAGENTA}2)${NC} Screen      - Feature UI with ViewModel and Views"
echo -e "                  (e.g., Settings, Profile, Dashboard)"
echo ""
echo -e "  ${MAGENTA}3)${NC} Coordinator - Navigation flow controller managing multiple screens"
echo -e "                  (e.g., AppCoordinator, OnboardingCoordinator)"
echo ""
echo -e "  ${MAGENTA}4)${NC} Utility     - General utility without abstracted interface"
echo -e "                  (e.g., Logger, Helpers, Extensions)"
echo ""
echo -e "  ${MAGENTA}5)${NC} Macro       - Swift Macro for code generation"
echo -e "                  (e.g., AutoInit, DependencyRequirements)"
echo ""

read -p "Enter choice (1-5): " MODULE_TYPE_CHOICE

case $MODULE_TYPE_CHOICE in
    1) MODULE_TYPE="client" ;;
    2) MODULE_TYPE="screen" ;;
    3) MODULE_TYPE="coordinator" ;;
    4) MODULE_TYPE="utility" ;;
    5) MODULE_TYPE="macro" ;;
    *)
        print_error "Invalid choice. Please enter 1-5."
        exit 1
        ;;
esac

print_success "Selected module type: $MODULE_TYPE"

# Phase 2: Get Module Name
print_header "Phase 2: Module Name"

read -p "Enter module name (PascalCase, e.g., Analytics): " MODULE_NAME
validate_module_name "$MODULE_NAME"

print_success "Module name: $MODULE_NAME"

# Phase 3: Determine Path
print_header "Phase 3: Module Location"

MODULES_ROOT=$(detect_modules_path)
print_info "Detected Modules root: $MODULES_ROOT"

case $MODULE_TYPE in
    client)
        MODULE_PATH="$MODULES_ROOT/Clients/$MODULE_NAME"
        SUBFOLDER="Clients"
        ;;
    screen)
        MODULE_PATH="$MODULES_ROOT/Screens/$MODULE_NAME"
        SUBFOLDER="Screens"
        ;;
    coordinator)
        MODULE_PATH="$MODULES_ROOT/Coordinators/$MODULE_NAME"
        SUBFOLDER="Coordinators"
        ;;
    utility)
        MODULE_PATH="$MODULES_ROOT/Utilities/$MODULE_NAME"
        SUBFOLDER="Utilities"
        ;;
    macro)
        MODULE_PATH="$MODULES_ROOT/Macros/$MODULE_NAME"
        SUBFOLDER="Macros"
        ;;
esac

print_info "Module will be created at: $MODULE_PATH"
echo ""

if [[ -d "$MODULE_PATH" ]]; then
    print_error "Directory already exists: $MODULE_PATH"
    if ! prompt_yes_no "Do you want to overwrite it?" "n"; then
        print_warning "Cancelled."
        exit 0
    fi
    rm -rf "$MODULE_PATH"
fi

# Summary before creation
print_header "Configuration Summary"
print_info "Module Type: $MODULE_TYPE"
print_info "Module Name: $MODULE_NAME"
print_info "Location: $MODULE_PATH"
echo ""

if ! prompt_yes_no "Proceed with generation?"; then
    print_warning "Generation cancelled."
    exit 0
fi

# Phase 4: Create Directory Structure
print_header "Phase 4: Creating Directory Structure"

case $MODULE_TYPE in
    client)
        mkdir -p "$MODULE_PATH/Sources/${MODULE_NAME}Interface"
        mkdir -p "$MODULE_PATH/Sources/${MODULE_NAME}"
        print_success "Created Client module structure"
        ;;
    screen)
        mkdir -p "$MODULE_PATH/Sources/${MODULE_NAME}Views"
        mkdir -p "$MODULE_PATH/Sources/${MODULE_NAME}"
        print_success "Created Screen module structure"
        ;;
    coordinator)
        mkdir -p "$MODULE_PATH/Sources/${MODULE_NAME}Views"
        mkdir -p "$MODULE_PATH/Sources/${MODULE_NAME}"
        print_success "Created Coordinator module structure"
        ;;
    utility)
        mkdir -p "$MODULE_PATH/Sources/${MODULE_NAME}"
        print_success "Created Utility module structure"
        ;;
    macro)
        mkdir -p "$MODULE_PATH/${MODULE_NAME}Macros/Sources"
        mkdir -p "$MODULE_PATH/${MODULE_NAME}MacrosImplementation/Sources"
        print_success "Created Macro module structure"
        ;;
esac

# Phase 5: Generate Package.swift
print_header "Phase 5: Generating Package.swift"

case $MODULE_TYPE in
    client)
        cat > "$MODULE_PATH/Package.swift" << EOF
// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "$MODULE_NAME",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "${MODULE_NAME}Interface", targets: ["${MODULE_NAME}Interface"]),
        .library(name: "$MODULE_NAME", targets: ["$MODULE_NAME"])
    ],
    dependencies: [
        // Add dependencies to other local packages if needed
        // .package(path: "../Core")
    ],
    targets: [
        .target(name: "${MODULE_NAME}Interface"),
        .target(
            name: "$MODULE_NAME",
            dependencies: [
                .target(name: "${MODULE_NAME}Interface")
            ]
        )
    ]
)
EOF
        ;;
    screen)
        cat > "$MODULE_PATH/Package.swift" << EOF
// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "$MODULE_NAME",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "${MODULE_NAME}Views", targets: ["${MODULE_NAME}Views"]),
        .library(name: "$MODULE_NAME", targets: ["$MODULE_NAME"])
    ],
    dependencies: [
        // Add client dependencies as needed
        // .package(path: "../../Clients/Logger"),
        .package(path: "../../Utilities/UIComponents"),
        .package(path: "../../Utilities/ModularNavigation"),
        .package(path: "../../Utilities/ModularDependencyContainer"),
    ],
    targets: [
        .target(
            name: "${MODULE_NAME}Views",
            dependencies: [
                .product(name: "UIComponents", package: "UIComponents"),
                .product(name: "ModularNavigation", package: "ModularNavigation"),
            ]
        ),
        .target(
            name: "$MODULE_NAME",
            dependencies: [
                .target(name: "${MODULE_NAME}Views"),
                .product(name: "ModularNavigation", package: "ModularNavigation"),
                .product(name: "ModularDependencyContainer", package: "ModularDependencyContainer"),
            ]
        )
    ]
)
EOF
        ;;
    coordinator)
        cat > "$MODULE_PATH/Package.swift" << EOF
// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "$MODULE_NAME",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "${MODULE_NAME}Views", targets: ["${MODULE_NAME}Views"]),
        .library(name: "$MODULE_NAME", targets: ["$MODULE_NAME"])
    ],
    dependencies: [
        .package(path: "../../Utilities/UIComponents"),
        .package(path: "../../Utilities/ModularNavigation"),
        .package(path: "../../Utilities/ModularDependencyContainer"),
        // Add screen modules this coordinator manages
        // .package(path: "../Screens/FeatureA"),
        // .package(path: "../Screens/FeatureB"),
    ],
    targets: [
        .target(
            name: "${MODULE_NAME}Views",
            dependencies: [
                .product(name: "UIComponents", package: "UIComponents"),
                .product(name: "ModularNavigation", package: "ModularNavigation")
            ]
        ),
        .target(
            name: "$MODULE_NAME",
            dependencies: [
                .target(name: "${MODULE_NAME}Views"),
                .product(name: "ModularNavigation", package: "ModularNavigation"),
                .product(name: "ModularDependencyContainer", package: "ModularDependencyContainer"),
                // Add screen module products
                // .product(name: "FeatureA", package: "FeatureA"),
            ]
        )
    ]
)
EOF
        ;;
    utility)
        cat > "$MODULE_PATH/Package.swift" << EOF
// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "$MODULE_NAME",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "$MODULE_NAME", targets: ["$MODULE_NAME"])
    ],
    dependencies: [
        // Add dependencies if needed
    ],
    targets: [
        .target(
            name: "$MODULE_NAME",
            dependencies: []
        )
    ]
)
EOF
        ;;
    macro)
        cat > "$MODULE_PATH/Package.swift" << EOF
// swift-tools-version: 5.9
import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "${MODULE_NAME}Macros",
    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13)],
    products: [
        .library(
            name: "${MODULE_NAME}Macros",
            targets: ["${MODULE_NAME}Macros"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0"),
    ],
    targets: [
        .macro(
            name: "${MODULE_NAME}MacrosImplementation",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ],
            path: "./${MODULE_NAME}MacrosImplementation/Sources"
        ),
        .target(
            name: "${MODULE_NAME}Macros",
            dependencies: ["${MODULE_NAME}MacrosImplementation"],
            path: "./${MODULE_NAME}Macros/Sources"
        )
    ]
)
EOF
        ;;
esac

print_success "Generated Package.swift"

# Phase 6: Generate Source Files
print_header "Phase 6: Generating Source Files"

case $MODULE_TYPE in
    client)
        # Interface file
        cat > "$MODULE_PATH/Sources/${MODULE_NAME}Interface/${MODULE_NAME}Protocol.swift" << EOF
import Foundation

/// Protocol defining the $MODULE_NAME interface
public protocol ${MODULE_NAME}Protocol {
    // TODO: Define your public API here
    func exampleMethod() async throws -> ${MODULE_NAME}Data
}

/// Data model used by $MODULE_NAME
public struct ${MODULE_NAME}Data: Equatable, Sendable {
    public let id: String
    public let value: String
    
    public init(id: String, value: String) {
        self.id = id
        self.value = value
    }
}

/// Mock implementation for testing and previews
public final class Mock${MODULE_NAME}: ${MODULE_NAME}Protocol, @unchecked Sendable {
    public var exampleResult: Result<${MODULE_NAME}Data, Error> = .success(
        ${MODULE_NAME}Data(id: "mock-1", value: "Mock Data")
    )
    
    public init() {}
    
    public func exampleMethod() async throws -> ${MODULE_NAME}Data {
        try await Task.sleep(for: .milliseconds(100))
        return try exampleResult.get()
    }
}
EOF
        print_success "Generated ${MODULE_NAME}Protocol.swift"
        
        # Re-export file
        cat > "$MODULE_PATH/Sources/${MODULE_NAME}/${MODULE_NAME}.swift" << EOF
// Re-export the Interface so users only need to import $MODULE_NAME
@_exported import ${MODULE_NAME}Interface
EOF
        print_success "Generated ${MODULE_NAME}.swift (re-export)"
        
        # Concrete implementation
        cat > "$MODULE_PATH/Sources/${MODULE_NAME}/${MODULE_NAME}Client.swift" << EOF
import Foundation
import ${MODULE_NAME}Interface

/// Concrete implementation of $MODULE_NAME
public final class ${MODULE_NAME}Client: ${MODULE_NAME}Protocol, @unchecked Sendable {
    
    public init() {}
    
    public func exampleMethod() async throws -> ${MODULE_NAME}Data {
        // TODO: Real implementation here
        try await Task.sleep(for: .milliseconds(500))
        
        return ${MODULE_NAME}Data(
            id: UUID().uuidString,
            value: "Real data from $MODULE_NAME"
        )
    }
}
EOF
        print_success "Generated ${MODULE_NAME}Client.swift"
        ;;
        
    screen)
        # Namespace enum
        cat > "$MODULE_PATH/Sources/${MODULE_NAME}/${MODULE_NAME}.swift" << EOF
/// Namespace for $MODULE_NAME module
/// Use for grouping related types when needed (e.g., ${MODULE_NAME}.SomeType)
public enum $MODULE_NAME { }
EOF
        print_success "Generated ${MODULE_NAME}.swift (namespace)"
        
        # ViewState file
        cat > "$MODULE_PATH/Sources/${MODULE_NAME}Views/${MODULE_NAME}ViewState.swift" << EOF
import Foundation
import UIComponents

/// Immutable snapshot of the UI's current display state
/// Contains only data the View needs to render - no business logic
@Copyable
public struct ${MODULE_NAME}ViewState: Equatable {
    public let title: String
    public let isLoading: Bool
    public let errorMessage: String?
    
    public init(
        title: String = "$MODULE_NAME",
        isLoading: Bool = false,
        errorMessage: String? = nil
    ) {
        self.title = title
        self.isLoading = isLoading
        self.errorMessage = errorMessage
    }
}

/// All possible user actions from this view
public enum ${MODULE_NAME}Action {
    case onAppear
    case refreshTapped
    case dismissErrorTapped
}
EOF
        print_success "Generated ${MODULE_NAME}ViewState.swift"
        
        # View file
        cat > "$MODULE_PATH/Sources/${MODULE_NAME}Views/${MODULE_NAME}View.swift" << EOF
import SwiftUI

/// Lightweight view for $MODULE_NAME
/// Pure presentation - no business logic, no ViewModel knowledge
/// Accepts state + onAction closure (DreamState pattern)
public struct ${MODULE_NAME}View: View {
    public let state: ${MODULE_NAME}ViewState
    public let onAction: (${MODULE_NAME}Action) -> Void
    
    public init(
        state: ${MODULE_NAME}ViewState,
        onAction: @escaping (${MODULE_NAME}Action) -> Void = { _ in }
    ) {
        self.state = state
        self.onAction = onAction
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            Text(state.title)
                .font(.largeTitle)
                .bold()
            
            if state.isLoading {
                ProgressView()
            } else if let errorMessage = state.errorMessage {
                VStack {
                    Text("Error: \(errorMessage)")
                        .foregroundStyle(.red)
                    Button("Dismiss") {
                        onAction(.dismissErrorTapped)
                    }
                }
            } else {
                // TODO: Add your content here
                Text("Content goes here")
            }
            
            Button("Refresh") {
                onAction(.refreshTapped)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .onAppear {
            onAction(.onAppear)
        }
    }
}

// MARK: - Previews

#Preview("Default") {
    ${MODULE_NAME}View(state: ${MODULE_NAME}ViewState())
}

#Preview("Loading") {
    ${MODULE_NAME}View(state: ${MODULE_NAME}ViewState(isLoading: true))
}

#Preview("Error") {
    ${MODULE_NAME}View(state: ${MODULE_NAME}ViewState(errorMessage: "Something went wrong"))
}
EOF
        print_success "Generated ${MODULE_NAME}View.swift"
        
        # ViewModel file
        cat > "$MODULE_PATH/Sources/${MODULE_NAME}/${MODULE_NAME}ViewModel.swift" << EOF
import Foundation
import SwiftUI
import ${MODULE_NAME}Views

/// ViewModel for $MODULE_NAME
/// Uses computed ViewState pattern (DreamState default)
/// Private domain state, public computed viewState
@MainActor
@Observable
public final class ${MODULE_NAME}ViewModel {
    // MARK: - Private Domain State
    
    private var isLoading = false
    private var errorMessage: String?
    
    // MARK: - Computed ViewState (automatically updates when domain state changes)
    
    public var viewState: ${MODULE_NAME}ViewState {
        ${MODULE_NAME}ViewState(
            title: "$MODULE_NAME",
            isLoading: isLoading,
            errorMessage: errorMessage
        )
    }
    
    // MARK: - Init
    
    public init() {}
    
    // MARK: - Public Methods (called by RootView in response to Actions)
    
    public func loadData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // TODO: Load data from dependencies
            try await Task.sleep(for: .milliseconds(500))
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    public func dismissError() {
        errorMessage = nil
    }
}
EOF
        print_success "Generated ${MODULE_NAME}ViewModel.swift"
        
        # RootView file
        cat > "$MODULE_PATH/Sources/${MODULE_NAME}/${MODULE_NAME}RootView.swift" << EOF
import Foundation
import SwiftUI
import ${MODULE_NAME}Views

/// RootView - bridges ViewModel to View
/// Owns the ViewModel, dispatches Actions to ViewModel methods
public struct ${MODULE_NAME}RootView: View {
    @State private var viewModel: ${MODULE_NAME}ViewModel
    
    public init(viewModel: ${MODULE_NAME}ViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }
    
    public var body: some View {
        ${MODULE_NAME}View(
            state: viewModel.viewState,
            onAction: { action in
                switch action {
                case .onAppear:
                    Task {
                        await viewModel.loadData()
                    }
                case .refreshTapped:
                    Task {
                        await viewModel.loadData()
                    }
                case .dismissErrorTapped:
                    viewModel.dismissError()
                }
            }
        )
    }
}

#Preview {
    ${MODULE_NAME}RootView(
        viewModel: ${MODULE_NAME}ViewModel()
    )
}
EOF
        print_success "Generated ${MODULE_NAME}RootView.swift"
        ;;
        
    coordinator)
        # Namespace enum
        cat > "$MODULE_PATH/Sources/${MODULE_NAME}/${MODULE_NAME}.swift" << EOF
/// Namespace for $MODULE_NAME module
/// Use for grouping related types when needed
public enum $MODULE_NAME { }
EOF
        print_success "Generated ${MODULE_NAME}.swift (namespace)"
        
        # ViewState file
        cat > "$MODULE_PATH/Sources/${MODULE_NAME}Views/${MODULE_NAME}ViewState.swift" << EOF
import Foundation
import UIComponents

/// Immutable snapshot of the coordinator's current display state
@Copyable
public struct ${MODULE_NAME}ViewState: Equatable {
    public enum CurrentScreen: Equatable {
        case screenA
        case screenB
        // TODO: Add screens this coordinator manages
    }
    
    public let currentScreen: CurrentScreen
    public let isNavigating: Bool
    
    public init(
        currentScreen: CurrentScreen = .screenA,
        isNavigating: Bool = false
    ) {
        self.currentScreen = currentScreen
        self.isNavigating = isNavigating
    }
}

/// All possible navigation actions
public enum ${MODULE_NAME}Action {
    case navigateToScreenA
    case navigateToScreenB
    case handleDeepLink(URL)
}
EOF
        print_success "Generated ${MODULE_NAME}ViewState.swift"
        
        # View file
        cat > "$MODULE_PATH/Sources/${MODULE_NAME}Views/${MODULE_NAME}View.swift" << EOF
import SwiftUI

/// Coordinator view that switches between managed screens
public struct ${MODULE_NAME}View<ScreenAView: View, ScreenBView: View>: View {
    public let state: ${MODULE_NAME}ViewState
    public let onAction: (${MODULE_NAME}Action) -> Void
    public let screenAView: () -> ScreenAView
    public let screenBView: () -> ScreenBView
    
    public init(
        state: ${MODULE_NAME}ViewState,
        onAction: @escaping (${MODULE_NAME}Action) -> Void = { _ in },
        @ViewBuilder screenAView: @escaping () -> ScreenAView,
        @ViewBuilder screenBView: @escaping () -> ScreenBView
    ) {
        self.state = state
        self.onAction = onAction
        self.screenAView = screenAView
        self.screenBView = screenBView
    }
    
    public var body: some View {
        Group {
            switch state.currentScreen {
            case .screenA:
                screenAView()
            case .screenB:
                screenBView()
            }
        }
    }
}

// MARK: - Previews

#Preview("Screen A") {
    ${MODULE_NAME}View(
        state: ${MODULE_NAME}ViewState(currentScreen: .screenA),
        screenAView: { Text("Screen A") },
        screenBView: { Text("Screen B") }
    )
}

#Preview("Screen B") {
    ${MODULE_NAME}View(
        state: ${MODULE_NAME}ViewState(currentScreen: .screenB),
        screenAView: { Text("Screen A") },
        screenBView: { Text("Screen B") }
    )
}
EOF
        print_success "Generated ${MODULE_NAME}View.swift"
        
        # ViewModel file
        cat > "$MODULE_PATH/Sources/${MODULE_NAME}/${MODULE_NAME}ViewModel.swift" << EOF
import Foundation
import SwiftUI
import ${MODULE_NAME}Views

/// ViewModel for $MODULE_NAME
/// Manages navigation state between screens
@MainActor
@Observable
public final class ${MODULE_NAME}ViewModel {
    // MARK: - Private State
    
    private var currentScreen: ${MODULE_NAME}ViewState.CurrentScreen = .screenA
    private var isNavigating = false
    
    // MARK: - Computed ViewState
    
    public var viewState: ${MODULE_NAME}ViewState {
        ${MODULE_NAME}ViewState(
            currentScreen: currentScreen,
            isNavigating: isNavigating
        )
    }
    
    // MARK: - Init
    
    public init() {}
    
    // MARK: - Navigation Methods
    
    public func navigateToScreenA() {
        currentScreen = .screenA
    }
    
    public func navigateToScreenB() {
        currentScreen = .screenB
    }
    
    public func handleDeepLink(_ url: URL) {
        // TODO: Parse URL and navigate accordingly
    }
}
EOF
        print_success "Generated ${MODULE_NAME}ViewModel.swift"
        
        # RootView file
        cat > "$MODULE_PATH/Sources/${MODULE_NAME}/${MODULE_NAME}RootView.swift" << EOF
import Foundation
import SwiftUI
import ${MODULE_NAME}Views
// TODO: Import screen modules
// import FeatureA
// import FeatureB

/// RootView - bridges ViewModel to View and provides screen implementations
public struct ${MODULE_NAME}RootView: View {
    @State private var viewModel: ${MODULE_NAME}ViewModel
    
    // TODO: Add dependencies for child screens
    // private let featureADependencies: FeatureA.Dependencies
    
    public init(
        viewModel: ${MODULE_NAME}ViewModel
    ) {
        self._viewModel = State(initialValue: viewModel)
    }
    
    public var body: some View {
        ${MODULE_NAME}View(
            state: viewModel.viewState,
            onAction: { action in
                switch action {
                case .navigateToScreenA:
                    viewModel.navigateToScreenA()
                case .navigateToScreenB:
                    viewModel.navigateToScreenB()
                case .handleDeepLink(let url):
                    viewModel.handleDeepLink(url)
                }
            },
            screenAView: {
                // TODO: Replace with actual screen
                // FeatureARootView(viewModel: FeatureAViewModel(...))
                Text("Screen A Placeholder")
            },
            screenBView: {
                // TODO: Replace with actual screen
                // FeatureBRootView(viewModel: FeatureBViewModel(...))
                Text("Screen B Placeholder")
            }
        )
    }
}

#Preview {
    ${MODULE_NAME}RootView(
        viewModel: ${MODULE_NAME}ViewModel()
    )
}
EOF
        print_success "Generated ${MODULE_NAME}RootView.swift"
        ;;
        
    utility)
        cat > "$MODULE_PATH/Sources/${MODULE_NAME}/${MODULE_NAME}.swift" << EOF
import Foundation

/// $MODULE_NAME - General purpose utility
/// TODO: Describe what this utility provides
public final class $MODULE_NAME {
    
    public init() {}
    
    // TODO: Add your implementation here
    public func exampleMethod() {
        // Implementation
    }
}
EOF
        print_success "Generated ${MODULE_NAME}.swift"
        ;;
        
    macro)
        # Macro definition
        cat > "$MODULE_PATH/${MODULE_NAME}Macros/Sources/${MODULE_NAME}.swift" << EOF
/// TODO: Description of what the macro does
/// 
/// Example usage:
/// \`\`\`swift
/// @$MODULE_NAME
/// struct MyType { }
/// \`\`\`
@attached(member, names: named(init))
public macro $MODULE_NAME() = #externalMacro(
    module: "${MODULE_NAME}MacrosImplementation",
    type: "${MODULE_NAME}Macro"
)
EOF
        print_success "Generated ${MODULE_NAME}.swift (macro definition)"
        
        # Macro implementation
        cat > "$MODULE_PATH/${MODULE_NAME}MacrosImplementation/Sources/${MODULE_NAME}Macro.swift" << EOF
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct ${MODULE_NAME}Macro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // TODO: Macro implementation here
        // Parse declaration, generate code
        return []
    }
}
EOF
        print_success "Generated ${MODULE_NAME}Macro.swift"
        
        # Plugin registration
        cat > "$MODULE_PATH/${MODULE_NAME}MacrosImplementation/Sources/Plugin.swift" << EOF
import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct ${MODULE_NAME}Plugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ${MODULE_NAME}Macro.self,
    ]
}
EOF
        print_success "Generated Plugin.swift"
        ;;
esac

# Final Summary
print_header "Generation Complete! ✅"

echo "Module created at:"
print_success "$MODULE_PATH"
echo ""

echo "Files created:"
case $MODULE_TYPE in
    client)
        print_success "Package.swift"
        print_success "Sources/${MODULE_NAME}Interface/${MODULE_NAME}Protocol.swift"
        print_success "Sources/${MODULE_NAME}/${MODULE_NAME}.swift (re-export)"
        print_success "Sources/${MODULE_NAME}/${MODULE_NAME}Client.swift"
        ;;
    screen)
        print_success "Package.swift"
        print_success "Sources/${MODULE_NAME}/${MODULE_NAME}.swift (namespace)"
        print_success "Sources/${MODULE_NAME}Views/${MODULE_NAME}ViewState.swift"
        print_success "Sources/${MODULE_NAME}Views/${MODULE_NAME}View.swift"
        print_success "Sources/${MODULE_NAME}/${MODULE_NAME}ViewModel.swift"
        print_success "Sources/${MODULE_NAME}/${MODULE_NAME}RootView.swift"
        ;;
    coordinator)
        print_success "Package.swift"
        print_success "Sources/${MODULE_NAME}/${MODULE_NAME}.swift (namespace)"
        print_success "Sources/${MODULE_NAME}Views/${MODULE_NAME}ViewState.swift"
        print_success "Sources/${MODULE_NAME}Views/${MODULE_NAME}View.swift"
        print_success "Sources/${MODULE_NAME}/${MODULE_NAME}ViewModel.swift"
        print_success "Sources/${MODULE_NAME}/${MODULE_NAME}RootView.swift"
        ;;
    utility)
        print_success "Package.swift"
        print_success "Sources/${MODULE_NAME}/${MODULE_NAME}.swift"
        ;;
    macro)
        print_success "Package.swift"
        print_success "${MODULE_NAME}Macros/Sources/${MODULE_NAME}.swift"
        print_success "${MODULE_NAME}MacrosImplementation/Sources/${MODULE_NAME}Macro.swift"
        print_success "${MODULE_NAME}MacrosImplementation/Sources/Plugin.swift"
        ;;
esac

echo ""
print_header "Next Steps"
echo ""
print_info "1. Update Modules/Package.swift to add this module:"
echo ""
echo -e "   ${CYAN}// In dependencies array:${NC}"
echo -e "   .package(path: \"$SUBFOLDER/$MODULE_NAME\"),"
echo ""
echo -e "   ${CYAN}// In ModulesTestTarget dependencies:${NC}"
if [[ "$MODULE_TYPE" == "macro" ]]; then
    echo -e "   .product(name: \"${MODULE_NAME}Macros\", package: \"${MODULE_NAME}\"),"
else
    echo -e "   .product(name: \"$MODULE_NAME\", package: \"$MODULE_NAME\"),"
fi
echo ""
print_info "2. Close and reopen Xcode to recognize the new package"
print_info "3. Build the project (Cmd+B) to verify everything compiles"
print_info "4. Implement the TODO items in the generated files"
echo ""
print_info "For more details, see: .claude/skills/module_creation/SKILL.md"
echo ""

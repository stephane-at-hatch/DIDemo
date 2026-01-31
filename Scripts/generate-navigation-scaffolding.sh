#!/bin/bash

#
# ModularNavigation Scaffolding Generator
# 
# This script generates the boilerplate navigation files for an iOS module
# following the ModularNavigation pattern. Supports both namespaced and
# non-namespaced patterns.
#
# Usage:
#   ./generate-navigation-scaffolding.sh <ModuleName> [ModulePath]
#
# Examples:
#   ./generate-navigation-scaffolding.sh UserProfile
#   ./generate-navigation-scaffolding.sh UserProfile /path/to/Modules/Screens/UserProfile
#
# Version: 1.3
# Based on: ios_modular_navigation/SKILL.md v1.4
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
        print_error "Module name must be PascalCase (e.g., UserProfile, AdultScreen)"
        exit 1
    fi
}

# Convert PascalCase to camelCase
to_camel_case() {
    local str=$1
    echo "$(echo "${str:0:1}" | tr '[:upper:]' '[:lower:]')${str:1}"
}

# Capitalize first letter
capitalize() {
    local str=$1
    echo "$(echo "${str:0:1}" | tr '[:lower:]' '[:upper:]')${str:1}"
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

# Prompt for multiline input (destinations)
prompt_destinations() {
    local prompt=$1
    local varname=$2
    local destinations=()
    
    echo -e "${CYAN}$prompt${NC}"
    echo -e "  (Enter destinations one per line. Empty line to finish)"
    echo -e "  Format: destinationName or destinationName(paramName: ParamType)"
    echo ""
    
    while true; do
        read -p "  → " destination
        if [[ -z "$destination" ]]; then
            break
        fi
        destinations+=("$destination")
    done
    
    eval "$varname=(\"\${destinations[@]}\")"
}

# Parse destination into components: name|params
parse_destination() {
    local dest=$1
    local name="" params=""
    
    if [[ "$dest" =~ ^([a-zA-Z0-9]+)\((.+)\)$ ]]; then
        name="${BASH_REMATCH[1]}"
        params="${BASH_REMATCH[2]}"
    else
        name="$dest"
        params=""
    fi
    
    echo "$name|$params"
}

# Generate enum case from destination
generate_enum_case() {
    local dest=$1
    local indent=${2:-"        "}
    local parsed=$(parse_destination "$dest")
    local name=$(echo "$parsed" | cut -d'|' -f1)
    local params=$(echo "$parsed" | cut -d'|' -f2)
    
    if [[ -z "$params" ]]; then
        echo "${indent}case $name"
    else
        echo "${indent}case $name($params)"
    fi
}

# Generate let bindings for switch case
generate_let_bindings() {
    local params=$1
    if [[ -z "$params" ]]; then
        echo ""
        return
    fi
    
    IFS=',' read -ra param_array <<< "$params"
    local binding_parts=()
    for param in "${param_array[@]}"; do
        param=$(echo "$param" | xargs)
        param_name=$(echo "$param" | cut -d':' -f1 | xargs)
        binding_parts+=("let $param_name")
    done
    echo "($(IFS=', '; echo "${binding_parts[*]}"))"
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

# Find most recently created module of a given type
find_most_recent_module() {
    local modules_root=$1
    local subfolder=$2
    local search_path="$modules_root/$subfolder"
    
    if [[ ! -d "$search_path" ]]; then
        echo ""
        return
    fi
    
    # Find the most recently modified directory (module) in the subfolder
    local most_recent=$(find "$search_path" -maxdepth 1 -mindepth 1 -type d -exec stat -f "%m %N" {} \; 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)
    
    if [[ -n "$most_recent" ]]; then
        basename "$most_recent"
    else
        echo ""
    fi
}

#
# MAIN SCRIPT
#

print_header "ModularNavigation Scaffolding Generator"

# Phase 0: Select Module Type
print_header "Phase 0: Select Module Type"

echo -e "${CYAN}What type of module are you adding navigation to?${NC}"
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
    1) MODULE_TYPE="client"; SUBFOLDER="Clients" ;;
    2) MODULE_TYPE="screen"; SUBFOLDER="Screens" ;;
    3) MODULE_TYPE="coordinator"; SUBFOLDER="Coordinators" ;;
    4) MODULE_TYPE="utility"; SUBFOLDER="Utilities" ;;
    5) MODULE_TYPE="macro"; SUBFOLDER="Macros" ;;
    *)
        print_error "Invalid choice. Please enter 1-5."
        exit 1
        ;;
esac

print_success "Selected module type: $MODULE_TYPE"

# Detect modules root
MODULES_ROOT=$(detect_modules_path)
print_info "Detected Modules root: $MODULES_ROOT"

# Find most recently created module of this type
MOST_RECENT_MODULE=$(find_most_recent_module "$MODULES_ROOT" "$SUBFOLDER")

# Parse arguments (for backwards compatibility)
MODULE_NAME=${1:-}
MODULE_PATH=${2:-}

if [[ -z "$MODULE_NAME" ]]; then
    if [[ -n "$MOST_RECENT_MODULE" ]]; then
        read -p "Enter module name (PascalCase, press Enter for '$MOST_RECENT_MODULE'): " MODULE_NAME
        MODULE_NAME=${MODULE_NAME:-$MOST_RECENT_MODULE}
    else
        read -p "Enter module name (PascalCase, e.g., UserProfile): " MODULE_NAME
    fi
fi

validate_module_name "$MODULE_NAME"

# Auto-compute path based on module type and name
DEFAULT_PATH="$MODULES_ROOT/$SUBFOLDER/$MODULE_NAME"

if [[ -z "$MODULE_PATH" ]]; then
    read -p "Enter module path (press Enter for '$DEFAULT_PATH'): " MODULE_PATH
    MODULE_PATH=${MODULE_PATH:-$DEFAULT_PATH}
fi

# Resolve to absolute path if it exists
if [[ -d "$MODULE_PATH" ]]; then
    MODULE_PATH=$(cd "$MODULE_PATH" && pwd)
fi

print_step "Module Type: $MODULE_TYPE"
print_step "Module: $MODULE_NAME"
print_step "Path: $MODULE_PATH"
echo ""

# Phase 1: Ask about namespacing
print_header "Phase 1: Namespace Configuration"

print_info "Namespaced navigation uses extensions on an existing enum:"
print_info "  public extension FeatureA { struct Destination: Hashable { ... } }"
print_info ""
print_info "Non-namespaced navigation uses traditional struct naming:"
print_info "  public struct FeatureADestination: Hashable { ... }"
echo ""

if prompt_yes_no "Should navigation types be namespaced?" "n"; then
    USE_NAMESPACE="true"
    read -p "Enter the namespace enum name (press Enter for '$MODULE_NAME'): " NAMESPACE
    NAMESPACE=${NAMESPACE:-$MODULE_NAME}
    validate_module_name "$NAMESPACE"
    print_success "Using namespaced pattern under: $NAMESPACE"
else
    USE_NAMESPACE="false"
    NAMESPACE=""
    print_success "Using non-namespaced pattern"
fi

# Phase 2: Gather destination information
print_header "Phase 2: Destination Configuration"

print_step "Public destinations are accessible from other modules."
prompt_destinations "Enter PUBLIC destinations:" PUBLIC_DESTINATIONS

if prompt_yes_no "Does this module have INTERNAL destinations (only accessible within the module)?"; then
    prompt_destinations "Enter INTERNAL destinations:" INTERNAL_DESTINATIONS
else
    INTERNAL_DESTINATIONS=()
fi

if prompt_yes_no "Does this module navigate to EXTERNAL modules?"; then
    prompt_destinations "Enter EXTERNAL destinations (e.g., routine, contentPreview):" EXTERNAL_DESTINATIONS
else
    EXTERNAL_DESTINATIONS=()
fi

# Validate we have at least one destination
if [[ ${#PUBLIC_DESTINATIONS[@]} -eq 0 && ${#INTERNAL_DESTINATIONS[@]} -eq 0 && ${#EXTERNAL_DESTINATIONS[@]} -eq 0 ]]; then
    print_error "At least one public, internal, or external destination is required."
    exit 1
fi

# Test builder option
if prompt_yes_no "Generate test builder for unit testing?" "n"; then
    GENERATE_TEST_BUILDER="true"
else
    GENERATE_TEST_BUILDER="false"
fi

# Summary
print_header "Configuration Summary"
print_info "Module: $MODULE_NAME"
print_info "Path: $MODULE_PATH"
if [[ "$USE_NAMESPACE" == "true" ]]; then
    print_info "Namespace: $NAMESPACE (namespaced)"
else
    print_info "Namespace: none (non-namespaced)"
fi
echo ""
print_info "Public destinations: ${PUBLIC_DESTINATIONS[*]:-none}"
print_info "Internal destinations: ${INTERNAL_DESTINATIONS[*]:-none}"
print_info "External destinations: ${EXTERNAL_DESTINATIONS[*]:-none}"
print_info "Generate test builder: $GENERATE_TEST_BUILDER"
echo ""

if ! prompt_yes_no "Proceed with generation?"; then
    print_warning "Generation cancelled."
    exit 0
fi

# Phase 3: Create directory structure
print_header "Phase 3: Creating Directory Structure"

NAVIGATION_DIR="$MODULE_PATH/Sources/$MODULE_NAME/Navigation"
TESTS_DIR="$MODULE_PATH/Tests"

mkdir -p "$NAVIGATION_DIR"
print_success "Created $NAVIGATION_DIR"

if [[ "$GENERATE_TEST_BUILDER" == "true" ]]; then
    mkdir -p "$TESTS_DIR"
    print_success "Created $TESTS_DIR"
fi

# ============================================================================
# NAMESPACED GENERATION
# ============================================================================
if [[ "$USE_NAMESPACE" == "true" ]]; then

# --- Phase 4: Destination.swift (Namespaced) ---
print_header "Phase 4: Generating ${MODULE_NAME}Destination.swift (Namespaced)"
DESTINATION_FILE="$NAVIGATION_DIR/${MODULE_NAME}Destination.swift"

cat > "$DESTINATION_FILE" << EOF
import ModularNavigation
import SwiftUI

// MARK: - Destination Enum

public extension $NAMESPACE {
    struct Destination: Hashable {
EOF

# Public enum
if [[ ${#PUBLIC_DESTINATIONS[@]} -gt 0 ]]; then
    echo "        public enum Public: Hashable {" >> "$DESTINATION_FILE"
    for dest in "${PUBLIC_DESTINATIONS[@]}"; do
        generate_enum_case "$dest" "            " >> "$DESTINATION_FILE"
    done
    echo "        }" >> "$DESTINATION_FILE"
    echo "" >> "$DESTINATION_FILE"
fi

# Internal enum
if [[ ${#INTERNAL_DESTINATIONS[@]} -gt 0 ]]; then
    echo "        enum Internal: Hashable {" >> "$DESTINATION_FILE"
    for dest in "${INTERNAL_DESTINATIONS[@]}"; do
        generate_enum_case "$dest" "            " >> "$DESTINATION_FILE"
    done
    echo "        }" >> "$DESTINATION_FILE"
    echo "" >> "$DESTINATION_FILE"
fi

# External enum
if [[ ${#EXTERNAL_DESTINATIONS[@]} -gt 0 ]]; then
    echo "        enum External: Hashable {" >> "$DESTINATION_FILE"
    for dest in "${EXTERNAL_DESTINATIONS[@]}"; do
        generate_enum_case "$dest" "            " >> "$DESTINATION_FILE"
    done
    echo "        }" >> "$DESTINATION_FILE"
    echo "" >> "$DESTINATION_FILE"
fi

# DestinationType enum
echo "        enum DestinationType: Hashable {" >> "$DESTINATION_FILE"
[[ ${#PUBLIC_DESTINATIONS[@]} -gt 0 ]] && echo "            case \`public\`(Public)" >> "$DESTINATION_FILE"
[[ ${#INTERNAL_DESTINATIONS[@]} -gt 0 ]] && echo "            case \`internal\`(Internal)" >> "$DESTINATION_FILE"
[[ ${#EXTERNAL_DESTINATIONS[@]} -gt 0 ]] && echo "            case external(External)" >> "$DESTINATION_FILE"
echo "        }" >> "$DESTINATION_FILE"
echo "" >> "$DESTINATION_FILE"
echo "        var type: DestinationType" >> "$DESTINATION_FILE"
echo "" >> "$DESTINATION_FILE"

# Initializers
[[ ${#PUBLIC_DESTINATIONS[@]} -gt 0 ]] && cat >> "$DESTINATION_FILE" << 'EOF'
        init(_ destination: Public) {
            self.type = .public(destination)
        }
        
EOF
[[ ${#INTERNAL_DESTINATIONS[@]} -gt 0 ]] && cat >> "$DESTINATION_FILE" << 'EOF'
        init(_ destination: Internal) {
            self.type = .internal(destination)
        }
        
EOF
[[ ${#EXTERNAL_DESTINATIONS[@]} -gt 0 ]] && cat >> "$DESTINATION_FILE" << 'EOF'
        init(_ destination: External) {
            self.type = .external(destination)
        }
        
EOF

# Static factory methods
[[ ${#PUBLIC_DESTINATIONS[@]} -gt 0 ]] && cat >> "$DESTINATION_FILE" << 'EOF'
        public static func `public`(_ destination: Public) -> Self {
            self.init(destination)
        }
        
EOF
[[ ${#INTERNAL_DESTINATIONS[@]} -gt 0 ]] && cat >> "$DESTINATION_FILE" << 'EOF'
        static func `internal`(_ destination: Internal) -> Self {
            self.init(destination)
        }
        
EOF
[[ ${#EXTERNAL_DESTINATIONS[@]} -gt 0 ]] && cat >> "$DESTINATION_FILE" << 'EOF'
        static func external(_ destination: External) -> Self {
            self.init(destination)
        }
        
EOF

echo "    }" >> "$DESTINATION_FILE"
echo "}" >> "$DESTINATION_FILE"
echo "" >> "$DESTINATION_FILE"

# Builder (extends NAMESPACE, not NAMESPACE.Destination)
cat >> "$DESTINATION_FILE" << 'EOF'
// MARK: - Destination Builder

EOF
cat >> "$DESTINATION_FILE" << EOF
public extension $NAMESPACE {
    @MainActor
    struct DestinationBuilder<DestinationView: View> {
        public let buildDestination: ModularNavigation.DestinationBuilder<Destination, DestinationView>
        
        public init(
            buildDestination: @escaping ModularNavigation.DestinationBuilder<Destination, DestinationView>
        ) {
            self.buildDestination = buildDestination
        }
    }
}
EOF

print_success "Generated $DESTINATION_FILE"

# --- Phase 5: DestinationViewState.swift (Namespaced) ---
print_header "Phase 5: Generating ${MODULE_NAME}DestinationViewState.swift (Namespaced)"
VIEWSTATE_FILE="$NAVIGATION_DIR/${MODULE_NAME}DestinationViewState.swift"

cat > "$VIEWSTATE_FILE" << EOF
import ModularNavigation
import SwiftUI

// MARK: - Destination-Specific ViewStates

extension $NAMESPACE {
EOF

# ViewState structs
for dest in "${PUBLIC_DESTINATIONS[@]}"; do
    parsed=$(parse_destination "$dest")
    name=$(echo "$parsed" | cut -d'|' -f1)
    params=$(echo "$parsed" | cut -d'|' -f2)
    cap_name=$(capitalize "$name")
    
    echo "    struct ${cap_name}DestinationViewState {" >> "$VIEWSTATE_FILE"
    echo "        // TODO: Replace with actual ViewModel type" >> "$VIEWSTATE_FILE"
    echo "        let viewModel: Any?" >> "$VIEWSTATE_FILE"
    if [[ -n "$params" ]]; then
        IFS=',' read -ra param_array <<< "$params"
        for param in "${param_array[@]}"; do
            echo "        let $(echo "$param" | xargs)" >> "$VIEWSTATE_FILE"
        done
    fi
    echo "    }" >> "$VIEWSTATE_FILE"
    echo "" >> "$VIEWSTATE_FILE"
done

for dest in "${INTERNAL_DESTINATIONS[@]}"; do
    parsed=$(parse_destination "$dest")
    name=$(echo "$parsed" | cut -d'|' -f1)
    params=$(echo "$parsed" | cut -d'|' -f2)
    cap_name=$(capitalize "$name")
    
    echo "    struct ${cap_name}DestinationViewState {" >> "$VIEWSTATE_FILE"
    echo "        // TODO: Replace with actual ViewModel type" >> "$VIEWSTATE_FILE"
    echo "        let viewModel: Any?" >> "$VIEWSTATE_FILE"
    if [[ -n "$params" ]]; then
        IFS=',' read -ra param_array <<< "$params"
        for param in "${param_array[@]}"; do
            echo "        let $(echo "$param" | xargs)" >> "$VIEWSTATE_FILE"
        done
    fi
    echo "    }" >> "$VIEWSTATE_FILE"
    echo "" >> "$VIEWSTATE_FILE"
done

for dest in "${EXTERNAL_DESTINATIONS[@]}"; do
    parsed=$(parse_destination "$dest")
    name=$(echo "$parsed" | cut -d'|' -f1)
    cap_name=$(capitalize "$name")
    
    echo "    struct ${cap_name}DestinationViewState {" >> "$VIEWSTATE_FILE"
    echo "        // TODO: Add external module builder function" >> "$VIEWSTATE_FILE"
    echo "    }" >> "$VIEWSTATE_FILE"
    echo "" >> "$VIEWSTATE_FILE"
done

echo "}" >> "$VIEWSTATE_FILE"
echo "" >> "$VIEWSTATE_FILE"

# ViewState enum
cat >> "$VIEWSTATE_FILE" << EOF
// MARK: - ViewState Enum

extension $NAMESPACE {
    enum DestinationViewState {
EOF

for dest in "${PUBLIC_DESTINATIONS[@]}" "${INTERNAL_DESTINATIONS[@]}" "${EXTERNAL_DESTINATIONS[@]}"; do
    [[ -z "$dest" ]] && continue
    parsed=$(parse_destination "$dest")
    name=$(echo "$parsed" | cut -d'|' -f1)
    cap_name=$(capitalize "$name")
    echo "        case $name(${cap_name}DestinationViewState)" >> "$VIEWSTATE_FILE"
done

echo "    }" >> "$VIEWSTATE_FILE"
echo "}" >> "$VIEWSTATE_FILE"

print_success "Generated $VIEWSTATE_FILE"

# --- Phase 6: DestinationView.swift (Namespaced) ---
print_header "Phase 6: Generating ${MODULE_NAME}DestinationView.swift (Namespaced)"
DESTVIEW_FILE="$NAVIGATION_DIR/${MODULE_NAME}DestinationView.swift"

cat > "$DESTVIEW_FILE" << EOF
import ModularNavigation
import SwiftUI

public extension $NAMESPACE {
    struct DestinationView: View {
        let viewState: DestinationViewState
        let mode: NavigationMode
        let client: NavigationClient<Destination>
        
        init(
            viewState: DestinationViewState,
            mode: NavigationMode,
            client: NavigationClient<Destination>
        ) {
            self.viewState = viewState
            self.mode = mode
            self.client = client
        }
        
        public var body: some View {
            switch viewState {
EOF

for dest in "${PUBLIC_DESTINATIONS[@]}" "${INTERNAL_DESTINATIONS[@]}" "${EXTERNAL_DESTINATIONS[@]}"; do
    [[ -z "$dest" ]] && continue
    parsed=$(parse_destination "$dest")
    name=$(echo "$parsed" | cut -d'|' -f1)
    camel_name=$(to_camel_case "$name")
    echo "            case .$name(let model):" >> "$DESTVIEW_FILE"
    echo "                ${camel_name}View(model)" >> "$DESTVIEW_FILE"
done

cat >> "$DESTVIEW_FILE" << 'EOF'
            }
        }
        
        // MARK: - Destination Views
        
EOF

for dest in "${PUBLIC_DESTINATIONS[@]}" "${INTERNAL_DESTINATIONS[@]}"; do
    [[ -z "$dest" ]] && continue
    parsed=$(parse_destination "$dest")
    name=$(echo "$parsed" | cut -d'|' -f1)
    cap_name=$(capitalize "$name")
    camel_name=$(to_camel_case "$name")
    
    echo "        func ${camel_name}View(_ model: ${cap_name}DestinationViewState) -> some View {" >> "$DESTVIEW_FILE"
    echo "            // TODO: Implement ${name} view" >> "$DESTVIEW_FILE"
    echo "            Text(\"${name} View\")" >> "$DESTVIEW_FILE"
    echo "        }" >> "$DESTVIEW_FILE"
    echo "" >> "$DESTVIEW_FILE"
done

for dest in "${EXTERNAL_DESTINATIONS[@]}"; do
    [[ -z "$dest" ]] && continue
    parsed=$(parse_destination "$dest")
    name=$(echo "$parsed" | cut -d'|' -f1)
    cap_name=$(capitalize "$name")
    camel_name=$(to_camel_case "$name")
    
    echo "        func ${camel_name}View(_ model: ${cap_name}DestinationViewState) -> some View {" >> "$DESTVIEW_FILE"
    echo "            // TODO: Implement external navigation" >> "$DESTVIEW_FILE"
    echo "            Text(\"${name} External View\")" >> "$DESTVIEW_FILE"
    echo "        }" >> "$DESTVIEW_FILE"
    echo "" >> "$DESTVIEW_FILE"
done

echo "    }" >> "$DESTVIEW_FILE"
echo "}" >> "$DESTVIEW_FILE"

print_success "Generated $DESTVIEW_FILE"

# --- Phase 7: Destination+Live.swift (Namespaced) ---
print_header "Phase 7: Generating ${MODULE_NAME}Destination+Live.swift (Namespaced)"
LIVE_FILE="$NAVIGATION_DIR/${MODULE_NAME}Destination+Live.swift"

cat > "$LIVE_FILE" << EOF
import ModularNavigation
import SwiftUI

public extension $NAMESPACE {
    @MainActor
    static func liveBuilder(
        // TODO: Add production dependencies here
    ) -> DestinationBuilder<DestinationView> {
        DestinationBuilder { destination, mode, navigationClient in
            let viewState: DestinationViewState
            
            switch destination.type {
EOF

if [[ ${#PUBLIC_DESTINATIONS[@]} -gt 0 ]]; then
    echo "            case .public(let publicDestination):" >> "$LIVE_FILE"
    echo "                switch publicDestination {" >> "$LIVE_FILE"
    for dest in "${PUBLIC_DESTINATIONS[@]}"; do
        parsed=$(parse_destination "$dest")
        name=$(echo "$parsed" | cut -d'|' -f1)
        params=$(echo "$parsed" | cut -d'|' -f2)
        cap_name=$(capitalize "$name")
        let_bindings=$(generate_let_bindings "$params")
        
        echo "                case .$name$let_bindings:" >> "$LIVE_FILE"
        echo "                    viewState = .$name(${cap_name}DestinationViewState(" >> "$LIVE_FILE"
        echo "                        viewModel: nil // TODO: Create production ViewModel" >> "$LIVE_FILE"
        if [[ -n "$params" ]]; then
            IFS=',' read -ra param_array <<< "$params"
            for param in "${param_array[@]}"; do
                param_name=$(echo "$param" | cut -d':' -f1 | xargs)
                echo "                        , $param_name: $param_name" >> "$LIVE_FILE"
            done
        fi
        echo "                    ))" >> "$LIVE_FILE"
    done
    echo "                }" >> "$LIVE_FILE"
fi

if [[ ${#INTERNAL_DESTINATIONS[@]} -gt 0 ]]; then
    echo "            case .internal(let internalDestination):" >> "$LIVE_FILE"
    echo "                switch internalDestination {" >> "$LIVE_FILE"
    for dest in "${INTERNAL_DESTINATIONS[@]}"; do
        parsed=$(parse_destination "$dest")
        name=$(echo "$parsed" | cut -d'|' -f1)
        params=$(echo "$parsed" | cut -d'|' -f2)
        cap_name=$(capitalize "$name")
        let_bindings=$(generate_let_bindings "$params")
        
        echo "                case .$name$let_bindings:" >> "$LIVE_FILE"
        echo "                    viewState = .$name(${cap_name}DestinationViewState(" >> "$LIVE_FILE"
        echo "                        viewModel: nil // TODO: Create production ViewModel" >> "$LIVE_FILE"
        if [[ -n "$params" ]]; then
            IFS=',' read -ra param_array <<< "$params"
            for param in "${param_array[@]}"; do
                param_name=$(echo "$param" | cut -d':' -f1 | xargs)
                echo "                        , $param_name: $param_name" >> "$LIVE_FILE"
            done
        fi
        echo "                    ))" >> "$LIVE_FILE"
    done
    echo "                }" >> "$LIVE_FILE"
fi

if [[ ${#EXTERNAL_DESTINATIONS[@]} -gt 0 ]]; then
    echo "            case .external(let externalDestination):" >> "$LIVE_FILE"
    echo "                switch externalDestination {" >> "$LIVE_FILE"
    for dest in "${EXTERNAL_DESTINATIONS[@]}"; do
        parsed=$(parse_destination "$dest")
        name=$(echo "$parsed" | cut -d'|' -f1)
        cap_name=$(capitalize "$name")
        
        echo "                case .$name:" >> "$LIVE_FILE"
        echo "                    viewState = .$name(${cap_name}DestinationViewState())" >> "$LIVE_FILE"
    done
    echo "                }" >> "$LIVE_FILE"
fi

cat >> "$LIVE_FILE" << 'EOF'
            }
            
            return DestinationView(
                viewState: viewState,
                mode: mode,
                client: navigationClient
            )
        }
    }
}
EOF

print_success "Generated $LIVE_FILE"

# --- Phase 8: Destination+Mock.swift (Namespaced) ---
print_header "Phase 8: Generating ${MODULE_NAME}Destination+Mock.swift (Namespaced)"
MOCK_FILE="$NAVIGATION_DIR/${MODULE_NAME}Destination+Mock.swift"

cat > "$MOCK_FILE" << EOF
import ModularNavigation
import SwiftUI

public extension $NAMESPACE {
    @MainActor
    static func mockBuilder() -> DestinationBuilder<DestinationView> {
        DestinationBuilder { destination, mode, navigationClient in
            let viewState: DestinationViewState
            
            switch destination.type {
EOF

if [[ ${#PUBLIC_DESTINATIONS[@]} -gt 0 ]]; then
    echo "            case .public(let publicDestination):" >> "$MOCK_FILE"
    echo "                switch publicDestination {" >> "$MOCK_FILE"
    for dest in "${PUBLIC_DESTINATIONS[@]}"; do
        parsed=$(parse_destination "$dest")
        name=$(echo "$parsed" | cut -d'|' -f1)
        params=$(echo "$parsed" | cut -d'|' -f2)
        cap_name=$(capitalize "$name")
        let_bindings=$(generate_let_bindings "$params")
        
        echo "                case .$name$let_bindings:" >> "$MOCK_FILE"
        echo "                    viewState = .$name(${cap_name}DestinationViewState(" >> "$MOCK_FILE"
        echo "                        viewModel: nil // TODO: Create mock ViewModel" >> "$MOCK_FILE"
        if [[ -n "$params" ]]; then
            IFS=',' read -ra param_array <<< "$params"
            for param in "${param_array[@]}"; do
                param_name=$(echo "$param" | cut -d':' -f1 | xargs)
                echo "                        , $param_name: $param_name" >> "$MOCK_FILE"
            done
        fi
        echo "                    ))" >> "$MOCK_FILE"
    done
    echo "                }" >> "$MOCK_FILE"
fi

if [[ ${#INTERNAL_DESTINATIONS[@]} -gt 0 ]]; then
    echo "            case .internal(let internalDestination):" >> "$MOCK_FILE"
    echo "                switch internalDestination {" >> "$MOCK_FILE"
    for dest in "${INTERNAL_DESTINATIONS[@]}"; do
        parsed=$(parse_destination "$dest")
        name=$(echo "$parsed" | cut -d'|' -f1)
        params=$(echo "$parsed" | cut -d'|' -f2)
        cap_name=$(capitalize "$name")
        let_bindings=$(generate_let_bindings "$params")
        
        echo "                case .$name$let_bindings:" >> "$MOCK_FILE"
        echo "                    viewState = .$name(${cap_name}DestinationViewState(" >> "$MOCK_FILE"
        echo "                        viewModel: nil // TODO: Create mock ViewModel" >> "$MOCK_FILE"
        if [[ -n "$params" ]]; then
            IFS=',' read -ra param_array <<< "$params"
            for param in "${param_array[@]}"; do
                param_name=$(echo "$param" | cut -d':' -f1 | xargs)
                echo "                        , $param_name: $param_name" >> "$MOCK_FILE"
            done
        fi
        echo "                    ))" >> "$MOCK_FILE"
    done
    echo "                }" >> "$MOCK_FILE"
fi

if [[ ${#EXTERNAL_DESTINATIONS[@]} -gt 0 ]]; then
    echo "            case .external(let externalDestination):" >> "$MOCK_FILE"
    echo "                switch externalDestination {" >> "$MOCK_FILE"
    for dest in "${EXTERNAL_DESTINATIONS[@]}"; do
        parsed=$(parse_destination "$dest")
        name=$(echo "$parsed" | cut -d'|' -f1)
        cap_name=$(capitalize "$name")
        
        echo "                case .$name:" >> "$MOCK_FILE"
        echo "                    viewState = .$name(${cap_name}DestinationViewState())" >> "$MOCK_FILE"
    done
    echo "                }" >> "$MOCK_FILE"
fi

cat >> "$MOCK_FILE" << 'EOF'
            }
            
            return DestinationView(
                viewState: viewState,
                mode: mode,
                client: navigationClient
            )
        }
    }
}

// MARK: - SwiftUI Preview

EOF

# Updated preview format
first_dest=""
first_dest_type=""
if [[ ${#PUBLIC_DESTINATIONS[@]} -gt 0 ]]; then
    first_dest=$(parse_destination "${PUBLIC_DESTINATIONS[0]}" | cut -d'|' -f1)
    first_dest_type=".public(.$first_dest)"
elif [[ ${#INTERNAL_DESTINATIONS[@]} -gt 0 ]]; then
    first_dest=$(parse_destination "${INTERNAL_DESTINATIONS[0]}" | cut -d'|' -f1)
    first_dest_type=".internal(.$first_dest)"
fi

cat >> "$MOCK_FILE" << EOF
#Preview {
    let builder = $NAMESPACE.mockBuilder()
    let rootClient = NavigationClient<RootDestination>.root()
    
    NavigationDestinationView(
        previousClient: rootClient,
        destination: $first_dest_type,
        mode: .root,
        builderFunction: builder.buildDestination
    )
}
EOF

print_success "Generated $MOCK_FILE"

# --- Phase 9: Test Builder (Namespaced) ---
if [[ "$GENERATE_TEST_BUILDER" == "true" ]]; then
    print_header "Phase 9: Generating Mock${MODULE_NAME}DestinationView.swift (Namespaced)"
    TEST_FILE="$TESTS_DIR/Mock${MODULE_NAME}DestinationView.swift"
    
    cat > "$TEST_FILE" << EOF
import SwiftUI
@testable import $MODULE_NAME

extension $NAMESPACE {
    struct MockDestinationView: View {
        let destination: Destination
        
        var body: some View {
            switch destination.type {
EOF

    colors=("blue" "green" "red" "orange" "purple" "pink" "yellow" "cyan")
    index=0

    if [[ ${#PUBLIC_DESTINATIONS[@]} -gt 0 ]]; then
        echo "            case .public(let publicDestination):" >> "$TEST_FILE"
        echo "                switch publicDestination {" >> "$TEST_FILE"
        for dest in "${PUBLIC_DESTINATIONS[@]}"; do
            parsed=$(parse_destination "$dest")
            name=$(echo "$parsed" | cut -d'|' -f1)
            params=$(echo "$parsed" | cut -d'|' -f2)
            color=${colors[$((index % ${#colors[@]}))]}
            pattern=""
            if [[ -n "$params" ]]; then
                IFS=',' read -ra param_array <<< "$params"
                underscores=()
                for _ in "${param_array[@]}"; do underscores+=("_"); done
                pattern="($(IFS=', '; echo "${underscores[*]}"))"
            fi
            echo "                case .$name$pattern:" >> "$TEST_FILE"
            echo "                    Color.$color.overlay(Text(\"$name\"))" >> "$TEST_FILE"
            ((index++))
        done
        echo "                }" >> "$TEST_FILE"
    fi

    if [[ ${#INTERNAL_DESTINATIONS[@]} -gt 0 ]]; then
        echo "            case .internal(let internalDestination):" >> "$TEST_FILE"
        echo "                switch internalDestination {" >> "$TEST_FILE"
        for dest in "${INTERNAL_DESTINATIONS[@]}"; do
            parsed=$(parse_destination "$dest")
            name=$(echo "$parsed" | cut -d'|' -f1)
            params=$(echo "$parsed" | cut -d'|' -f2)
            color=${colors[$((index % ${#colors[@]}))]}
            pattern=""
            if [[ -n "$params" ]]; then
                IFS=',' read -ra param_array <<< "$params"
                underscores=()
                for _ in "${param_array[@]}"; do underscores+=("_"); done
                pattern="($(IFS=', '; echo "${underscores[*]}"))"
            fi
            echo "                case .$name$pattern:" >> "$TEST_FILE"
            echo "                    Color.$color.overlay(Text(\"$name\"))" >> "$TEST_FILE"
            ((index++))
        done
        echo "                }" >> "$TEST_FILE"
    fi

    if [[ ${#EXTERNAL_DESTINATIONS[@]} -gt 0 ]]; then
        echo "            case .external(let externalDestination):" >> "$TEST_FILE"
        echo "                switch externalDestination {" >> "$TEST_FILE"
        for dest in "${EXTERNAL_DESTINATIONS[@]}"; do
            parsed=$(parse_destination "$dest")
            name=$(echo "$parsed" | cut -d'|' -f1)
            color=${colors[$((index % ${#colors[@]}))]}
            echo "                case .$name:" >> "$TEST_FILE"
            echo "                    Color.$color.overlay(Text(\"$name\"))" >> "$TEST_FILE"
            ((index++))
        done
        echo "                }" >> "$TEST_FILE"
    fi

    cat >> "$TEST_FILE" << EOF
            }
        }
    }
}

extension $NAMESPACE {
    @MainActor
    static func testBuilder() -> DestinationBuilder<MockDestinationView> {
        DestinationBuilder { destination, mode, navigationClient in
            MockDestinationView(destination: destination)
        }
    }
}
EOF

    print_success "Generated $TEST_FILE"
fi

# ============================================================================
# NON-NAMESPACED GENERATION
# ============================================================================
else

# --- Phase 4: Destination.swift (Non-Namespaced) ---
print_header "Phase 4: Generating ${MODULE_NAME}Destination.swift"
DESTINATION_FILE="$NAVIGATION_DIR/${MODULE_NAME}Destination.swift"

cat > "$DESTINATION_FILE" << EOF
import ModularNavigation
import SwiftUI

// MARK: - Destination Enum

public struct ${MODULE_NAME}Destination: Hashable {
EOF

if [[ ${#PUBLIC_DESTINATIONS[@]} -gt 0 ]]; then
    echo "    public enum Public: Hashable {" >> "$DESTINATION_FILE"
    for dest in "${PUBLIC_DESTINATIONS[@]}"; do
        generate_enum_case "$dest" >> "$DESTINATION_FILE"
    done
    echo "    }" >> "$DESTINATION_FILE"
    echo "" >> "$DESTINATION_FILE"
fi

if [[ ${#INTERNAL_DESTINATIONS[@]} -gt 0 ]]; then
    echo "    enum Internal: Hashable {" >> "$DESTINATION_FILE"
    for dest in "${INTERNAL_DESTINATIONS[@]}"; do
        generate_enum_case "$dest" >> "$DESTINATION_FILE"
    done
    echo "    }" >> "$DESTINATION_FILE"
    echo "" >> "$DESTINATION_FILE"
fi

if [[ ${#EXTERNAL_DESTINATIONS[@]} -gt 0 ]]; then
    echo "    enum External: Hashable {" >> "$DESTINATION_FILE"
    for dest in "${EXTERNAL_DESTINATIONS[@]}"; do
        generate_enum_case "$dest" >> "$DESTINATION_FILE"
    done
    echo "    }" >> "$DESTINATION_FILE"
    echo "" >> "$DESTINATION_FILE"
fi

echo "    enum DestinationType: Hashable {" >> "$DESTINATION_FILE"
[[ ${#PUBLIC_DESTINATIONS[@]} -gt 0 ]] && echo "        case \`public\`(Public)" >> "$DESTINATION_FILE"
[[ ${#INTERNAL_DESTINATIONS[@]} -gt 0 ]] && echo "        case \`internal\`(Internal)" >> "$DESTINATION_FILE"
[[ ${#EXTERNAL_DESTINATIONS[@]} -gt 0 ]] && echo "        case external(External)" >> "$DESTINATION_FILE"
echo "    }" >> "$DESTINATION_FILE"
echo "" >> "$DESTINATION_FILE"
echo "    var type: DestinationType" >> "$DESTINATION_FILE"
echo "" >> "$DESTINATION_FILE"

[[ ${#PUBLIC_DESTINATIONS[@]} -gt 0 ]] && cat >> "$DESTINATION_FILE" << 'EOF'
    init(_ destination: Public) {
        self.type = .public(destination)
    }
    
EOF
[[ ${#INTERNAL_DESTINATIONS[@]} -gt 0 ]] && cat >> "$DESTINATION_FILE" << 'EOF'
    init(_ destination: Internal) {
        self.type = .internal(destination)
    }
    
EOF
[[ ${#EXTERNAL_DESTINATIONS[@]} -gt 0 ]] && cat >> "$DESTINATION_FILE" << 'EOF'
    init(_ destination: External) {
        self.type = .external(destination)
    }
    
EOF

[[ ${#PUBLIC_DESTINATIONS[@]} -gt 0 ]] && cat >> "$DESTINATION_FILE" << 'EOF'
    public static func `public`(_ destination: Public) -> Self {
        self.init(destination)
    }
    
EOF
[[ ${#INTERNAL_DESTINATIONS[@]} -gt 0 ]] && cat >> "$DESTINATION_FILE" << 'EOF'
    static func `internal`(_ destination: Internal) -> Self {
        self.init(destination)
    }
    
EOF
[[ ${#EXTERNAL_DESTINATIONS[@]} -gt 0 ]] && cat >> "$DESTINATION_FILE" << 'EOF'
    static func external(_ destination: External) -> Self {
        self.init(destination)
    }
    
EOF

echo "}" >> "$DESTINATION_FILE"
echo "" >> "$DESTINATION_FILE"

cat >> "$DESTINATION_FILE" << EOF
// MARK: - Destination Builder

@MainActor
public struct ${MODULE_NAME}DestinationBuilder<DestinationView: View> {
    public let buildDestination: DestinationBuilder<${MODULE_NAME}Destination, DestinationView>
    
    public init(
        buildDestination: @escaping DestinationBuilder<${MODULE_NAME}Destination, DestinationView>
    ) {
        self.buildDestination = buildDestination
    }
}
EOF

print_success "Generated $DESTINATION_FILE"

# --- Phase 5: DestinationViewState.swift (Non-Namespaced) ---
print_header "Phase 5: Generating ${MODULE_NAME}DestinationViewState.swift"
VIEWSTATE_FILE="$NAVIGATION_DIR/${MODULE_NAME}DestinationViewState.swift"

cat > "$VIEWSTATE_FILE" << EOF
import ModularNavigation
import SwiftUI

// MARK: - Destination-Specific ViewStates

EOF

for dest in "${PUBLIC_DESTINATIONS[@]}" "${INTERNAL_DESTINATIONS[@]}"; do
    [[ -z "$dest" ]] && continue
    parsed=$(parse_destination "$dest")
    name=$(echo "$parsed" | cut -d'|' -f1)
    params=$(echo "$parsed" | cut -d'|' -f2)
    cap_name=$(capitalize "$name")
    
    echo "struct ${MODULE_NAME}${cap_name}DestinationViewState {" >> "$VIEWSTATE_FILE"
    echo "    // TODO: Replace with actual ViewModel type" >> "$VIEWSTATE_FILE"
    echo "    let viewModel: Any?" >> "$VIEWSTATE_FILE"
    if [[ -n "$params" ]]; then
        IFS=',' read -ra param_array <<< "$params"
        for param in "${param_array[@]}"; do
            echo "    let $(echo "$param" | xargs)" >> "$VIEWSTATE_FILE"
        done
    fi
    echo "}" >> "$VIEWSTATE_FILE"
    echo "" >> "$VIEWSTATE_FILE"
done

for dest in "${EXTERNAL_DESTINATIONS[@]}"; do
    [[ -z "$dest" ]] && continue
    parsed=$(parse_destination "$dest")
    name=$(echo "$parsed" | cut -d'|' -f1)
    cap_name=$(capitalize "$name")
    
    echo "struct ${MODULE_NAME}${cap_name}DestinationViewState {" >> "$VIEWSTATE_FILE"
    echo "    // TODO: Add external module builder function" >> "$VIEWSTATE_FILE"
    echo "}" >> "$VIEWSTATE_FILE"
    echo "" >> "$VIEWSTATE_FILE"
done

cat >> "$VIEWSTATE_FILE" << EOF
// MARK: - ViewState Enum

enum ${MODULE_NAME}DestinationViewState {
EOF

for dest in "${PUBLIC_DESTINATIONS[@]}" "${INTERNAL_DESTINATIONS[@]}" "${EXTERNAL_DESTINATIONS[@]}"; do
    [[ -z "$dest" ]] && continue
    parsed=$(parse_destination "$dest")
    name=$(echo "$parsed" | cut -d'|' -f1)
    cap_name=$(capitalize "$name")
    echo "    case $name(${MODULE_NAME}${cap_name}DestinationViewState)" >> "$VIEWSTATE_FILE"
done

echo "}" >> "$VIEWSTATE_FILE"

print_success "Generated $VIEWSTATE_FILE"

# --- Phase 6: DestinationView.swift (Non-Namespaced) ---
print_header "Phase 6: Generating ${MODULE_NAME}DestinationView.swift"
DESTVIEW_FILE="$NAVIGATION_DIR/${MODULE_NAME}DestinationView.swift"

cat > "$DESTVIEW_FILE" << EOF
import ModularNavigation
import SwiftUI

public struct ${MODULE_NAME}DestinationView: View {
    let viewState: ${MODULE_NAME}DestinationViewState
    let mode: NavigationMode
    let client: NavigationClient<${MODULE_NAME}Destination>
    
    init(
        viewState: ${MODULE_NAME}DestinationViewState,
        mode: NavigationMode,
        client: NavigationClient<${MODULE_NAME}Destination>
    ) {
        self.viewState = viewState
        self.mode = mode
        self.client = client
    }
    
    public var body: some View {
        switch viewState {
EOF

for dest in "${PUBLIC_DESTINATIONS[@]}" "${INTERNAL_DESTINATIONS[@]}" "${EXTERNAL_DESTINATIONS[@]}"; do
    [[ -z "$dest" ]] && continue
    parsed=$(parse_destination "$dest")
    name=$(echo "$parsed" | cut -d'|' -f1)
    camel_name=$(to_camel_case "$name")
    echo "        case .$name(let model):" >> "$DESTVIEW_FILE"
    echo "            ${camel_name}View(model)" >> "$DESTVIEW_FILE"
done

cat >> "$DESTVIEW_FILE" << 'EOF'
        }
    }
    
    // MARK: - Destination Views
    
EOF

for dest in "${PUBLIC_DESTINATIONS[@]}" "${INTERNAL_DESTINATIONS[@]}"; do
    [[ -z "$dest" ]] && continue
    parsed=$(parse_destination "$dest")
    name=$(echo "$parsed" | cut -d'|' -f1)
    cap_name=$(capitalize "$name")
    camel_name=$(to_camel_case "$name")
    
    echo "    func ${camel_name}View(_ model: ${MODULE_NAME}${cap_name}DestinationViewState) -> some View {" >> "$DESTVIEW_FILE"
    echo "        // TODO: Implement ${name} view" >> "$DESTVIEW_FILE"
    echo "        Text(\"${name} View\")" >> "$DESTVIEW_FILE"
    echo "    }" >> "$DESTVIEW_FILE"
    echo "" >> "$DESTVIEW_FILE"
done

for dest in "${EXTERNAL_DESTINATIONS[@]}"; do
    [[ -z "$dest" ]] && continue
    parsed=$(parse_destination "$dest")
    name=$(echo "$parsed" | cut -d'|' -f1)
    cap_name=$(capitalize "$name")
    camel_name=$(to_camel_case "$name")
    
    echo "    func ${camel_name}View(_ model: ${MODULE_NAME}${cap_name}DestinationViewState) -> some View {" >> "$DESTVIEW_FILE"
    echo "        // TODO: Implement external navigation" >> "$DESTVIEW_FILE"
    echo "        Text(\"${name} External View\")" >> "$DESTVIEW_FILE"
    echo "    }" >> "$DESTVIEW_FILE"
    echo "" >> "$DESTVIEW_FILE"
done

echo "}" >> "$DESTVIEW_FILE"

print_success "Generated $DESTVIEW_FILE"

# --- Phase 7: Destination+Live.swift (Non-Namespaced) ---
print_header "Phase 7: Generating ${MODULE_NAME}Destination+Live.swift"
LIVE_FILE="$NAVIGATION_DIR/${MODULE_NAME}Destination+Live.swift"

cat > "$LIVE_FILE" << EOF
import ModularNavigation
import SwiftUI

extension ${MODULE_NAME}Destination {
    @MainActor
    public static func liveBuilder(
        // TODO: Add production dependencies here
    ) -> ${MODULE_NAME}DestinationBuilder<${MODULE_NAME}DestinationView> {
        ${MODULE_NAME}DestinationBuilder { destination, mode, navigationClient in
            let viewState: ${MODULE_NAME}DestinationViewState
            
            switch destination.type {
EOF

if [[ ${#PUBLIC_DESTINATIONS[@]} -gt 0 ]]; then
    echo "            case .public(let publicDestination):" >> "$LIVE_FILE"
    echo "                switch publicDestination {" >> "$LIVE_FILE"
    for dest in "${PUBLIC_DESTINATIONS[@]}"; do
        parsed=$(parse_destination "$dest")
        name=$(echo "$parsed" | cut -d'|' -f1)
        params=$(echo "$parsed" | cut -d'|' -f2)
        cap_name=$(capitalize "$name")
        let_bindings=$(generate_let_bindings "$params")
        
        echo "                case .$name$let_bindings:" >> "$LIVE_FILE"
        echo "                    viewState = .$name(${MODULE_NAME}${cap_name}DestinationViewState(" >> "$LIVE_FILE"
        echo "                        viewModel: nil // TODO: Create production ViewModel" >> "$LIVE_FILE"
        if [[ -n "$params" ]]; then
            IFS=',' read -ra param_array <<< "$params"
            for param in "${param_array[@]}"; do
                param_name=$(echo "$param" | cut -d':' -f1 | xargs)
                echo "                        , $param_name: $param_name" >> "$LIVE_FILE"
            done
        fi
        echo "                    ))" >> "$LIVE_FILE"
    done
    echo "                }" >> "$LIVE_FILE"
fi

if [[ ${#INTERNAL_DESTINATIONS[@]} -gt 0 ]]; then
    echo "            case .internal(let internalDestination):" >> "$LIVE_FILE"
    echo "                switch internalDestination {" >> "$LIVE_FILE"
    for dest in "${INTERNAL_DESTINATIONS[@]}"; do
        parsed=$(parse_destination "$dest")
        name=$(echo "$parsed" | cut -d'|' -f1)
        params=$(echo "$parsed" | cut -d'|' -f2)
        cap_name=$(capitalize "$name")
        let_bindings=$(generate_let_bindings "$params")
        
        echo "                case .$name$let_bindings:" >> "$LIVE_FILE"
        echo "                    viewState = .$name(${MODULE_NAME}${cap_name}DestinationViewState(" >> "$LIVE_FILE"
        echo "                        viewModel: nil // TODO: Create production ViewModel" >> "$LIVE_FILE"
        if [[ -n "$params" ]]; then
            IFS=',' read -ra param_array <<< "$params"
            for param in "${param_array[@]}"; do
                param_name=$(echo "$param" | cut -d':' -f1 | xargs)
                echo "                        , $param_name: $param_name" >> "$LIVE_FILE"
            done
        fi
        echo "                    ))" >> "$LIVE_FILE"
    done
    echo "                }" >> "$LIVE_FILE"
fi

if [[ ${#EXTERNAL_DESTINATIONS[@]} -gt 0 ]]; then
    echo "            case .external(let externalDestination):" >> "$LIVE_FILE"
    echo "                switch externalDestination {" >> "$LIVE_FILE"
    for dest in "${EXTERNAL_DESTINATIONS[@]}"; do
        parsed=$(parse_destination "$dest")
        name=$(echo "$parsed" | cut -d'|' -f1)
        cap_name=$(capitalize "$name")
        
        echo "                case .$name:" >> "$LIVE_FILE"
        echo "                    viewState = .$name(${MODULE_NAME}${cap_name}DestinationViewState())" >> "$LIVE_FILE"
    done
    echo "                }" >> "$LIVE_FILE"
fi

cat >> "$LIVE_FILE" << EOF
            }
            
            return ${MODULE_NAME}DestinationView(
                viewState: viewState,
                mode: mode,
                client: navigationClient
            )
        }
    }
}
EOF

print_success "Generated $LIVE_FILE"

# --- Phase 8: Destination+Mock.swift (Non-Namespaced) ---
print_header "Phase 8: Generating ${MODULE_NAME}Destination+Mock.swift"
MOCK_FILE="$NAVIGATION_DIR/${MODULE_NAME}Destination+Mock.swift"

cat > "$MOCK_FILE" << EOF
import ModularNavigation
import SwiftUI

extension ${MODULE_NAME}Destination {
    @MainActor
    public static func mockBuilder() -> ${MODULE_NAME}DestinationBuilder<${MODULE_NAME}DestinationView> {
        ${MODULE_NAME}DestinationBuilder { destination, mode, navigationClient in
            let viewState: ${MODULE_NAME}DestinationViewState
            
            switch destination.type {
EOF

if [[ ${#PUBLIC_DESTINATIONS[@]} -gt 0 ]]; then
    echo "            case .public(let publicDestination):" >> "$MOCK_FILE"
    echo "                switch publicDestination {" >> "$MOCK_FILE"
    for dest in "${PUBLIC_DESTINATIONS[@]}"; do
        parsed=$(parse_destination "$dest")
        name=$(echo "$parsed" | cut -d'|' -f1)
        params=$(echo "$parsed" | cut -d'|' -f2)
        cap_name=$(capitalize "$name")
        let_bindings=$(generate_let_bindings "$params")
        
        echo "                case .$name$let_bindings:" >> "$MOCK_FILE"
        echo "                    viewState = .$name(${MODULE_NAME}${cap_name}DestinationViewState(" >> "$MOCK_FILE"
        echo "                        viewModel: nil // TODO: Create mock ViewModel" >> "$MOCK_FILE"
        if [[ -n "$params" ]]; then
            IFS=',' read -ra param_array <<< "$params"
            for param in "${param_array[@]}"; do
                param_name=$(echo "$param" | cut -d':' -f1 | xargs)
                echo "                        , $param_name: $param_name" >> "$MOCK_FILE"
            done
        fi
        echo "                    ))" >> "$MOCK_FILE"
    done
    echo "                }" >> "$MOCK_FILE"
fi

if [[ ${#INTERNAL_DESTINATIONS[@]} -gt 0 ]]; then
    echo "            case .internal(let internalDestination):" >> "$MOCK_FILE"
    echo "                switch internalDestination {" >> "$MOCK_FILE"
    for dest in "${INTERNAL_DESTINATIONS[@]}"; do
        parsed=$(parse_destination "$dest")
        name=$(echo "$parsed" | cut -d'|' -f1)
        params=$(echo "$parsed" | cut -d'|' -f2)
        cap_name=$(capitalize "$name")
        let_bindings=$(generate_let_bindings "$params")
        
        echo "                case .$name$let_bindings:" >> "$MOCK_FILE"
        echo "                    viewState = .$name(${MODULE_NAME}${cap_name}DestinationViewState(" >> "$MOCK_FILE"
        echo "                        viewModel: nil // TODO: Create mock ViewModel" >> "$MOCK_FILE"
        if [[ -n "$params" ]]; then
            IFS=',' read -ra param_array <<< "$params"
            for param in "${param_array[@]}"; do
                param_name=$(echo "$param" | cut -d':' -f1 | xargs)
                echo "                        , $param_name: $param_name" >> "$MOCK_FILE"
            done
        fi
        echo "                    ))" >> "$MOCK_FILE"
    done
    echo "                }" >> "$MOCK_FILE"
fi

if [[ ${#EXTERNAL_DESTINATIONS[@]} -gt 0 ]]; then
    echo "            case .external(let externalDestination):" >> "$MOCK_FILE"
    echo "                switch externalDestination {" >> "$MOCK_FILE"
    for dest in "${EXTERNAL_DESTINATIONS[@]}"; do
        parsed=$(parse_destination "$dest")
        name=$(echo "$parsed" | cut -d'|' -f1)
        cap_name=$(capitalize "$name")
        
        echo "                case .$name:" >> "$MOCK_FILE"
        echo "                    viewState = .$name(${MODULE_NAME}${cap_name}DestinationViewState())" >> "$MOCK_FILE"
    done
    echo "                }" >> "$MOCK_FILE"
fi

cat >> "$MOCK_FILE" << EOF
            }
            
            return ${MODULE_NAME}DestinationView(
                viewState: viewState,
                mode: mode,
                client: navigationClient
            )
        }
    }
}

// MARK: - SwiftUI Preview

EOF

# Updated preview format for non-namespaced
first_dest=""
first_dest_type=""
if [[ ${#PUBLIC_DESTINATIONS[@]} -gt 0 ]]; then
    first_dest=$(parse_destination "${PUBLIC_DESTINATIONS[0]}" | cut -d'|' -f1)
    first_dest_type=".public(.$first_dest)"
elif [[ ${#INTERNAL_DESTINATIONS[@]} -gt 0 ]]; then
    first_dest=$(parse_destination "${INTERNAL_DESTINATIONS[0]}" | cut -d'|' -f1)
    first_dest_type=".internal(.$first_dest)"
fi

cat >> "$MOCK_FILE" << EOF
#Preview {
    let builder = ${MODULE_NAME}Destination.mockBuilder()
    let rootClient = NavigationClient<RootDestination>.root()
    
    NavigationDestinationView(
        previousClient: rootClient,
        destination: $first_dest_type,
        mode: .root,
        builderFunction: builder.buildDestination
    )
}
EOF

print_success "Generated $MOCK_FILE"

# --- Phase 9: Test Builder (Non-Namespaced) ---
if [[ "$GENERATE_TEST_BUILDER" == "true" ]]; then
    print_header "Phase 9: Generating Mock${MODULE_NAME}DestinationView.swift"
    TEST_FILE="$TESTS_DIR/Mock${MODULE_NAME}DestinationView.swift"
    
    cat > "$TEST_FILE" << EOF
import SwiftUI
@testable import $MODULE_NAME

struct Mock${MODULE_NAME}DestinationView: View {
    let destination: ${MODULE_NAME}Destination
    
    var body: some View {
        switch destination.type {
EOF

    colors=("blue" "green" "red" "orange" "purple" "pink" "yellow" "cyan")
    index=0

    if [[ ${#PUBLIC_DESTINATIONS[@]} -gt 0 ]]; then
        echo "        case .public(let publicDestination):" >> "$TEST_FILE"
        echo "            switch publicDestination {" >> "$TEST_FILE"
        for dest in "${PUBLIC_DESTINATIONS[@]}"; do
            parsed=$(parse_destination "$dest")
            name=$(echo "$parsed" | cut -d'|' -f1)
            params=$(echo "$parsed" | cut -d'|' -f2)
            color=${colors[$((index % ${#colors[@]}))]}
            pattern=""
            if [[ -n "$params" ]]; then
                IFS=',' read -ra param_array <<< "$params"
                underscores=()
                for _ in "${param_array[@]}"; do underscores+=("_"); done
                pattern="($(IFS=', '; echo "${underscores[*]}"))"
            fi
            echo "            case .$name$pattern:" >> "$TEST_FILE"
            echo "                Color.$color.overlay(Text(\"$name\"))" >> "$TEST_FILE"
            ((index++))
        done
        echo "            }" >> "$TEST_FILE"
    fi

    if [[ ${#INTERNAL_DESTINATIONS[@]} -gt 0 ]]; then
        echo "        case .internal(let internalDestination):" >> "$TEST_FILE"
        echo "            switch internalDestination {" >> "$TEST_FILE"
        for dest in "${INTERNAL_DESTINATIONS[@]}"; do
            parsed=$(parse_destination "$dest")
            name=$(echo "$parsed" | cut -d'|' -f1)
            params=$(echo "$parsed" | cut -d'|' -f2)
            color=${colors[$((index % ${#colors[@]}))]}
            pattern=""
            if [[ -n "$params" ]]; then
                IFS=',' read -ra param_array <<< "$params"
                underscores=()
                for _ in "${param_array[@]}"; do underscores+=("_"); done
                pattern="($(IFS=', '; echo "${underscores[*]}"))"
            fi
            echo "            case .$name$pattern:" >> "$TEST_FILE"
            echo "                Color.$color.overlay(Text(\"$name\"))" >> "$TEST_FILE"
            ((index++))
        done
        echo "            }" >> "$TEST_FILE"
    fi

    if [[ ${#EXTERNAL_DESTINATIONS[@]} -gt 0 ]]; then
        echo "        case .external(let externalDestination):" >> "$TEST_FILE"
        echo "            switch externalDestination {" >> "$TEST_FILE"
        for dest in "${EXTERNAL_DESTINATIONS[@]}"; do
            parsed=$(parse_destination "$dest")
            name=$(echo "$parsed" | cut -d'|' -f1)
            color=${colors[$((index % ${#colors[@]}))]}
            echo "            case .$name:" >> "$TEST_FILE"
            echo "                Color.$color.overlay(Text(\"$name\"))" >> "$TEST_FILE"
            ((index++))
        done
        echo "            }" >> "$TEST_FILE"
    fi

    cat >> "$TEST_FILE" << EOF
        }
    }
}

extension ${MODULE_NAME}Destination {
    @MainActor
    public static func testBuilder() -> ${MODULE_NAME}DestinationBuilder<Mock${MODULE_NAME}DestinationView> {
        ${MODULE_NAME}DestinationBuilder { destination, mode, navigationClient in
            Mock${MODULE_NAME}DestinationView(destination: destination)
        }
    }
}
EOF

    print_success "Generated $TEST_FILE"
fi

fi # End of namespace conditional

# ============================================================================
# FINAL SUMMARY
# ============================================================================
print_header "Generation Complete! ✅"

echo "Files created:"
echo ""
print_success "$DESTINATION_FILE"
print_success "$VIEWSTATE_FILE"
print_success "$DESTVIEW_FILE"
print_success "$LIVE_FILE"
print_success "$MOCK_FILE"
[[ "$GENERATE_TEST_BUILDER" == "true" ]] && print_success "$TEST_FILE"

echo ""
print_header "Next Steps"
echo ""
print_info "1. Replace 'Any?' placeholders with actual ViewModel types"
print_info "2. Implement view content in each destination view function"
print_info "3. Add production dependencies to liveBuilder"
print_info "4. Add mock dependencies to mockBuilder"
print_info "5. Wire module into parent navigation"
print_info "6. Test navigation flow in simulator"
echo ""
print_info "For more details, see: .claude/skills/ios_modular_navigation/SKILL.md"
echo ""

#!/bin/bash

#
# ModularDependencies Scaffolding Generator
# 
# This script generates the DependencyRequirements boilerplate for an iOS module.
#
# Usage:
#   ./generate-dependencies-scaffolding.sh <ModuleName> [ModulePath]
#
# Examples:
#   ./generate-dependencies-scaffolding.sh FeatureA
#   ./generate-dependencies-scaffolding.sh FeatureA /path/to/Modules/Screens/FeatureA
#
# Version: 1.0
# Based on: modular_dependencies/SKILL.md v1.0
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

print_step() {
    echo -e "${CYAN}➤ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "  $1"
}

# Validate module name (PascalCase)
validate_module_name() {
    local name=$1
    if [[ ! "$name" =~ ^[A-Z][a-zA-Z0-9]*$ ]]; then
        print_error "Module name must be PascalCase (e.g., FeatureA, UserProfile)"
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

# Prompt for multiline input (dependencies)
prompt_dependencies() {
    local prompt=$1
    local varname=$2
    local dependencies=()
    
    echo -e "${CYAN}$prompt${NC}"
    echo -e "  (Enter dependency protocol names one per line. Empty line to finish)"
    echo -e "  Examples: AnalyticsClientProtocol, Logger, NetworkClientProtocol"
    echo ""
    
    while true; do
        read -p "  → " dependency
        if [[ -z "$dependency" ]]; then
            break
        fi
        dependencies+=("$dependency")
    done
    
    eval "$varname=(\"\${dependencies[@]}\")"
}

# Prompt for multiline input (input requirements)
prompt_input_requirements() {
    local prompt=$1
    local varname=$2
    local inputs=()
    
    echo -e "${CYAN}$prompt${NC}"
    echo -e "  (Enter input type names one per line. Empty line to finish)"
    echo -e "  Examples: LoggerConfiguration, FeatureFlags, UserContext"
    echo ""
    
    while true; do
        read -p "  → " input
        if [[ -z "$input" ]]; then
            break
        fi
        inputs+=("$input")
    done
    
    eval "$varname=(\"\${inputs[@]}\")"
}

#
# MAIN SCRIPT
#

print_header "ModularDependencies Scaffolding Generator"

# Phase 0: Select Module Type
print_header "Phase 0: Select Module Type"

echo -e "${CYAN}What type of module are you adding dependencies to?${NC}"
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
        read -p "Enter module name (PascalCase, e.g., FeatureA): " MODULE_NAME
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

print_info "Namespaced dependencies use extensions on an existing enum:"
print_info "  extension FeatureA { public struct Dependencies: DependencyRequirements { ... } }"
print_info ""
print_info "Non-namespaced dependencies use traditional struct naming:"
print_info "  public struct FeatureADependencies: DependencyRequirements { ... }"
echo ""

if prompt_yes_no "Should dependencies be namespaced?" "n"; then
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

# Phase 2: Gather dependencies
print_header "Phase 2: Dependency Configuration"

prompt_dependencies "Enter required dependencies:" DEPENDENCIES

if [[ ${#DEPENDENCIES[@]} -eq 0 ]]; then
    print_info "No dependencies specified - module will pass through container to children."
fi

echo ""
print_info "Input requirements are runtime configuration values provided by the parent"
print_info "module before building this module (e.g., LoggerConfiguration, FeatureFlags)."
echo ""

if prompt_yes_no "Does this module have input requirements?" "n"; then
    prompt_input_requirements "Enter input requirements:" INPUT_REQUIREMENTS
else
    INPUT_REQUIREMENTS=()
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
print_info "Dependencies:"
for dep in "${DEPENDENCIES[@]}"; do
    print_info "  - $dep"
done
echo ""
if [[ ${#INPUT_REQUIREMENTS[@]} -gt 0 ]]; then
    print_info "Input Requirements:"
    for input in "${INPUT_REQUIREMENTS[@]}"; do
        print_info "  - $input"
    done
else
    print_info "Input Requirements: (none)"
fi
echo ""

if ! prompt_yes_no "Proceed with generation?"; then
    print_warning "Generation cancelled."
    exit 0
fi

# Phase 3: Create directory structure
print_header "Phase 3: Creating Directory Structure"

# Dependencies go in the main target folder (Sources/<ModuleName>/Dependencies)
DEPENDENCIES_DIR="$MODULE_PATH/Sources/$MODULE_NAME/Dependencies"

mkdir -p "$DEPENDENCIES_DIR"
print_success "Created $DEPENDENCIES_DIR"

# Phase 4: Generate Dependencies file
print_header "Phase 4: Generating Dependencies File"

if [[ "$USE_NAMESPACE" == "true" ]]; then
    # Namespaced version
    DEPS_FILE="$DEPENDENCIES_DIR/${MODULE_NAME}Dependencies.swift"
    
    cat > "$DEPS_FILE" << EOF
import ModularDependencyContainer

extension $NAMESPACE {
    @DependencyRequirements([
EOF

    # Add requirements
    for i in "${!DEPENDENCIES[@]}"; do
        dep="${DEPENDENCIES[$i]}"
        echo "        Requirement($dep.self)," >> "$DEPS_FILE"
    done

    # Add inputs section if there are input requirements
    if [[ ${#INPUT_REQUIREMENTS[@]} -gt 0 ]]; then
        cat >> "$DEPS_FILE" << EOF
    ],
    inputs: [
EOF
        for i in "${!INPUT_REQUIREMENTS[@]}"; do
            input="${INPUT_REQUIREMENTS[$i]}"
            echo "        InputRequirement($input.self)," >> "$DEPS_FILE"
        done
        cat >> "$DEPS_FILE" << EOF
    ])
EOF
    else
        cat >> "$DEPS_FILE" << EOF
    ])
EOF
    fi

    cat >> "$DEPS_FILE" << EOF
    public struct Dependencies: DependencyRequirements {
        public func registerDependencies(in container: ModularDependencyContainer.DependencyContainer<Dependencies>) {
            // Register any dependencies this module provides
        }
    }
}
EOF

else
    # Non-namespaced version
    DEPS_FILE="$DEPENDENCIES_DIR/${MODULE_NAME}Dependencies.swift"
    
    cat > "$DEPS_FILE" << EOF
import ModularDependencyContainer

@DependencyRequirements([
EOF

    # Add requirements
    for i in "${!DEPENDENCIES[@]}"; do
        dep="${DEPENDENCIES[$i]}"
        echo "    Requirement($dep.self)," >> "$DEPS_FILE"
    done

    # Add inputs section if there are input requirements
    if [[ ${#INPUT_REQUIREMENTS[@]} -gt 0 ]]; then
        cat >> "$DEPS_FILE" << EOF
],
inputs: [
EOF
        for i in "${!INPUT_REQUIREMENTS[@]}"; do
            input="${INPUT_REQUIREMENTS[$i]}"
            echo "    InputRequirement($input.self)," >> "$DEPS_FILE"
        done
        cat >> "$DEPS_FILE" << EOF
])
EOF
    else
        cat >> "$DEPS_FILE" << EOF
])
EOF
    fi

    cat >> "$DEPS_FILE" << EOF
public struct ${MODULE_NAME}Dependencies: DependencyRequirements {
    public func registerDependencies(in container: ModularDependencyContainer.DependencyContainer<${MODULE_NAME}Dependencies>) {
        // Register any dependencies this module provides
    }
}
EOF

fi

print_success "Generated $DEPS_FILE"

# Final Summary
print_header "Generation Complete! ✅"

echo "File created:"
echo ""
print_success "$DEPS_FILE"

echo ""
print_header "Next Steps"
echo ""
print_info "1. Add any necessary imports for the dependency protocols"
print_info "2. If this module provides dependencies, implement registerDependencies"
print_info "3. Build the module to verify the macro expansion works correctly"
echo ""
print_info "For more details, see: .claude/skills/modular_dependencies/SKILL.md"
echo ""

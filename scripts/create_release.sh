#!/bin/bash

# Release script for temphist_app
# This script handles version bumping, production configuration, and tagging

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to get current version from pubspec.yaml
get_current_version() {
    grep "^version:" pubspec.yaml | sed 's/version: //' | sed 's/+.*//'
}

# Function to get current build number from pubspec.yaml
get_current_build() {
    grep "^version:" pubspec.yaml | sed 's/.*+//'
}

# Function to update version in pubspec.yaml
update_version() {
    local new_version=$1
    local new_build=$2
    local current_version=$(get_current_version)
    local current_build=$(get_current_build)
    
    print_status "Updating version from $current_version+$current_build to $new_version+$new_build"
    
    # Update pubspec.yaml
    sed -i '' "s/^version: .*/version: $new_version+$new_build/" pubspec.yaml
    
    print_success "Version updated in pubspec.yaml"
}

# Function to validate version format
validate_version() {
    local version=$1
    if [[ ! $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        print_error "Invalid version format. Use semantic versioning (e.g., 1.2.3)"
        exit 1
    fi
}

# Function to check if we're on main branch
check_branch() {
    local current_branch=$(git branch --show-current)
    if [ "$current_branch" != "main" ]; then
        print_error "You must be on the main branch to create a release. Current branch: $current_branch"
        print_status "Run: git checkout main"
        exit 1
    fi
}

# Function to check for uncommitted changes
check_clean_working_directory() {
    if ! git diff-index --quiet HEAD --; then
        print_error "Working directory has uncommitted changes. Please commit or stash them first."
        git status --short
        exit 1
    fi
}

# Function to check if develop is merged
check_develop_merged() {
    local develop_commit=$(git rev-parse develop)
    local main_commit=$(git rev-parse main)
    
    if ! git merge-base --is-ancestor $develop_commit $main_commit; then
        print_warning "Develop branch is not merged into main. Do you want to continue anyway? (y/N)"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            print_status "Release cancelled. Merge develop into main first."
            exit 1
        fi
    fi
}

# Main release function
create_release() {
    local version_type=$1
    local custom_version=$2
    
    print_status "Starting release process..."
    
    # Validate inputs
    if [ -z "$version_type" ]; then
        print_error "Version type is required. Use: patch, minor, major, or custom"
        echo "Usage: $0 <patch|minor|major|custom> [version]"
        echo "Examples:"
        echo "  $0 patch          # 1.0.0 -> 1.0.1"
        echo "  $0 minor          # 1.0.0 -> 1.1.0"
        echo "  $0 major          # 1.0.0 -> 2.0.0"
        echo "  $0 custom 1.2.3   # Set specific version"
        exit 1
    fi
    
    # Check prerequisites
    check_branch
    check_clean_working_directory
    check_develop_merged
    
    # Run tests to ensure everything is working
    print_status "Running tests to ensure code quality..."
    if ! flutter test; then
        print_error "Tests failed! Please fix the failing tests before creating a release."
        exit 1
    fi
    print_success "All tests passed!"
    
    # Run code analysis to catch any linting issues
    print_status "Running code analysis..."
    local analyze_output
    analyze_output=$(flutter analyze 2>&1)
    local analyze_exit_code=$?
    
    # Check if there are any warnings or errors (not just info-level issues)
    if echo "$analyze_output" | grep -E "(warning|error)" > /dev/null; then
        print_error "Code analysis found warnings or errors! Please fix them before creating a release."
        echo "$analyze_output"
        exit 1
    fi
    
    if [ $analyze_exit_code -eq 0 ]; then
        print_success "Code analysis passed with no issues!"
    else
        print_warning "Code analysis found info-level issues (style suggestions) - these won't block the release:"
        echo "$analyze_output"
        print_status "Continuing with release..."
    fi
    
    # Get current version
    local current_version=$(get_current_version)
    local current_build=$(get_current_build)
    local new_version
    local new_build=$((current_build + 1))
    
    # Calculate new version
    case $version_type in
        "patch")
            IFS='.' read -r major minor patch <<< "$current_version"
            new_version="$major.$minor.$((patch + 1))"
            ;;
        "minor")
            IFS='.' read -r major minor patch <<< "$current_version"
            new_version="$major.$((minor + 1)).0"
            ;;
        "major")
            IFS='.' read -r major minor patch <<< "$current_version"
            new_version="$((major + 1)).0.0"
            ;;
        "custom")
            if [ -z "$custom_version" ]; then
                print_error "Custom version requires a version number (e.g., 1.2.3)"
                exit 1
            fi
            validate_version "$custom_version"
            new_version="$custom_version"
            ;;
        *)
            print_error "Invalid version type: $version_type"
            echo "Use: patch, minor, major, or custom"
            exit 1
            ;;
    esac
    
    validate_version "$new_version"
    
    print_status "Creating release $new_version+$new_build"
    print_status "Current version: $current_version+$current_build"
    
    # Update version in pubspec.yaml
    update_version "$new_version" "$new_build"
    
    # Commit version update
    git add pubspec.yaml
    git commit -m "Bump version to $new_version+$new_build"
    
    # Create and push tag
    local tag_name="v$new_version"
    print_status "Creating tag: $tag_name"
    git tag -a "$tag_name" -m "Release $new_version"
    
    # Push changes and tags
    print_status "Pushing changes and tags to remote..."
    git push origin main
    git push origin "$tag_name"
    
    print_success "Release $new_version created successfully!"
    print_status "Tag: $tag_name"
    print_status "Build: $new_build"
    echo ""
    print_status "To build for production:"
    print_status "  flutter build apk --release"
    print_status "  flutter build ios --release"
    print_status "  flutter build web --release"
    echo ""
    print_status "The app will automatically use production configuration when built with --release flag"
}

# Show help if no arguments
if [ $# -eq 0 ]; then
    echo "Temphist App Release Script"
    echo ""
    echo "Usage: $0 <version_type> [version]"
    echo ""
    echo "Version types:"
    echo "  patch    - Increment patch version (1.0.0 -> 1.0.1)"
    echo "  minor    - Increment minor version (1.0.0 -> 1.1.0)"
    echo "  major    - Increment major version (1.0.0 -> 2.0.0)"
    echo "  custom   - Set specific version (requires version parameter)"
    echo ""
    echo "Examples:"
    echo "  $0 patch"
    echo "  $0 minor"
    echo "  $0 major"
    echo "  $0 custom 1.2.3"
    echo ""
    echo "Prerequisites:"
    echo "  - Must be on main branch"
    echo "  - Working directory must be clean"
    echo "  - Develop branch should be merged"
    exit 0
fi

# Run the release process
create_release "$1" "$2"

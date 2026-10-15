#!/bin/bash

# Release script for temphist_app
#
# A release is two steps, so the version bump can go through a pull request:
#
#   bump  Run on a branch. Runs the tests and analyzer, bumps the version in
#         pubspec.yaml and commits it. Does not push and does not tag.
#   tag   Run on main after the PR has merged. Tags the merged commit with
#         v<version> (read from pubspec.yaml) and pushes the tag.

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

# Function to check for uncommitted changes
check_clean_working_directory() {
    if ! git diff-index --quiet HEAD --; then
        print_error "Working directory has uncommitted changes. Please commit or stash them first."
        git status --short
        exit 1
    fi
}

# Function to check if develop is merged into main
check_develop_merged() {
    # Nothing to check if there is no develop branch.
    if ! git rev-parse --verify --quiet develop > /dev/null; then
        return
    fi

    local develop_commit=$(git rev-parse develop)
    local main_commit=$(git rev-parse main)

    if ! git merge-base --is-ancestor "$develop_commit" "$main_commit"; then
        print_warning "Develop branch is not merged into main. Do you want to continue anyway? (y/N)"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            print_status "Release cancelled. Merge develop into main first."
            exit 1
        fi
    fi
}

# Run the test suite and the analyzer; exit if either finds a problem.
run_quality_checks() {
    # Run tests to ensure everything is working
    print_status "Running tests to ensure code quality..."
    if ! flutter test; then
        print_error "Tests failed! Please fix the failing tests before creating a release."
        exit 1
    fi
    print_success "All tests passed!"

    # Run code analysis to catch any linting issues
    print_status "Running code analysis..."

    # Run flutter analyze and capture output
    local analyze_output
    if ! analyze_output=$(flutter analyze 2>&1); then
        # Check if there are any warnings or errors (not just info-level issues)
        if echo "$analyze_output" | grep -E "(warning|error)" > /dev/null; then
            print_error "Code analysis found warnings or errors! Please fix them before creating a release."
            echo "$analyze_output"
            exit 1
        else
            print_warning "Code analysis found info-level issues (style suggestions) - these won't block the release:"
            echo "$analyze_output"
            print_status "Continuing with release..."
        fi
    else
        print_success "Code analysis passed with no issues!"
    fi
}

# Sets NEW_VERSION from the current version and the requested bump type.
# (A global rather than echo/$(...) so error messages are not captured.)
calculate_new_version() {
    local version_type=$1
    local custom_version=$2
    local current_version=$(get_current_version)
    local major minor patch

    case $version_type in
        "patch")
            IFS='.' read -r major minor patch <<< "$current_version"
            NEW_VERSION="$major.$minor.$((patch + 1))"
            ;;
        "minor")
            IFS='.' read -r major minor patch <<< "$current_version"
            NEW_VERSION="$major.$((minor + 1)).0"
            ;;
        "major")
            IFS='.' read -r major minor patch <<< "$current_version"
            NEW_VERSION="$((major + 1)).0.0"
            ;;
        "custom")
            if [ -z "$custom_version" ]; then
                print_error "Custom version requires a version number (e.g., 1.2.3)"
                exit 1
            fi
            NEW_VERSION="$custom_version"
            ;;
        *)
            print_error "Invalid version type: $version_type"
            echo "Use: patch, minor, major, or custom"
            exit 1
            ;;
    esac

    validate_version "$NEW_VERSION"
}

# bump: bump pubspec.yaml on the current (non-main) branch and commit it.
bump_version() {
    local version_type=$1
    local custom_version=$2

    if [ -z "$version_type" ]; then
        print_error "Version type is required. Use: patch, minor, major, or custom"
        echo "Usage: $0 bump <patch|minor|major|custom> [version]"
        exit 1
    fi

    local current_branch=$(git branch --show-current)
    if [ -z "$current_branch" ]; then
        print_error "You are on a detached HEAD. Check out a branch first."
        exit 1
    fi
    if [ "$current_branch" = "main" ]; then
        print_error "Don't bump on main. Create a branch and open a PR instead."
        print_status "Run: git switch -c release/<version>"
        exit 1
    fi

    check_clean_working_directory

    # Work out and validate the new version before the slow checks run.
    calculate_new_version "$version_type" "$custom_version"
    local current_version=$(get_current_version)
    local current_build=$(get_current_build)
    local new_build=$(date +%Y%m%d%H%M)

    if git rev-parse --verify --quiet "refs/tags/v$NEW_VERSION" > /dev/null; then
        print_error "Tag v$NEW_VERSION already exists locally. Choose a different version."
        exit 1
    fi

    print_status "Bumping $current_version+$current_build -> $NEW_VERSION+$new_build on branch $current_branch"

    run_quality_checks

    update_version "$NEW_VERSION" "$new_build"

    git add pubspec.yaml
    git commit -m "Bump version to $NEW_VERSION+$new_build"

    print_success "Version bumped to $NEW_VERSION+$new_build and committed."
    echo ""
    print_status "Next steps:"
    print_status "  1. git push -u origin $current_branch"
    print_status "  2. Open a pull request into main and merge it"
    print_status "  3. git switch main && git pull && $0 tag"
}

# tag: tag the merged version on main and push the tag.
tag_release() {
    local current_branch=$(git branch --show-current)
    if [ "$current_branch" != "main" ]; then
        print_error "You must be on the main branch to tag a release. Current branch: ${current_branch:-detached HEAD}"
        print_status "Run: git switch main && git pull"
        exit 1
    fi

    check_clean_working_directory

    # The tag must point at a commit that is on the remote, so main has to
    # match origin/main exactly (neither behind nor carrying unpushed commits).
    print_status "Fetching origin..."
    git fetch --quiet origin
    local local_main=$(git rev-parse main)
    local remote_main=$(git rev-parse origin/main)
    if [ "$local_main" != "$remote_main" ]; then
        print_error "Local main is not in sync with origin/main."
        print_status "Run: git pull   (and push or drop any local-only commits)"
        exit 1
    fi

    check_develop_merged

    local version=$(get_current_version)
    validate_version "$version"
    local tag_name="v$version"

    if git rev-parse --verify --quiet "refs/tags/$tag_name" > /dev/null; then
        print_error "Tag $tag_name already exists locally."
        print_status "pubspec.yaml is still at $version; has the version bump been merged to main?"
        exit 1
    fi
    if git ls-remote --exit-code --tags origin "refs/tags/$tag_name" > /dev/null 2>&1; then
        print_error "Tag $tag_name already exists on origin."
        print_status "pubspec.yaml is still at $version; has the version bump been merged to main?"
        exit 1
    fi

    print_status "Tag:    $tag_name"
    print_status "Commit: $(git log -1 --format='%h %s' main)"
    print_status "Build:  $(get_current_build)"
    print_warning "Create tag $tag_name and push it to origin? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        print_status "Cancelled. Nothing was tagged or pushed."
        exit 1
    fi

    git tag -a "$tag_name" -m "Release $version"
    git push origin "$tag_name"

    print_success "Release $version tagged and pushed as $tag_name!"
    echo ""
    print_status "To build for production:"
    print_status "  flutter build apk --release"
    print_status "  flutter build ios --release"
    print_status "  flutter build web --release"
    echo ""
    print_status "The app will automatically use production configuration when built with --release flag"
}

usage() {
    echo "Temphist App Release Script"
    echo ""
    echo "A release is two steps, so the version bump can go through a PR:"
    echo ""
    echo "  $0 bump <version_type> [version]   (on a branch)"
    echo "  $0 tag                             (on main, after the PR merges)"
    echo ""
    echo "bump runs the tests and analyzer, updates pubspec.yaml and commits."
    echo "It does not push or tag."
    echo ""
    echo "Version types:"
    echo "  patch    - Increment patch version (1.0.0 -> 1.0.1)"
    echo "  minor    - Increment minor version (1.0.0 -> 1.1.0)"
    echo "  major    - Increment major version (1.0.0 -> 2.0.0)"
    echo "  custom   - Set specific version (requires version parameter)"
    echo ""
    echo "tag creates v<version> from pubspec.yaml on main and pushes the tag."
    echo ""
    echo "Examples:"
    echo "  git switch -c release/1.4.0"
    echo "  $0 bump custom 1.4.0"
    echo "  git push -u origin release/1.4.0   # open a PR, merge it"
    echo "  git switch main && git pull"
    echo "  $0 tag"
    echo ""
    echo "Prerequisites:"
    echo "  bump - on a branch other than main, working directory clean"
    echo "  tag  - on main, in sync with origin/main, working directory clean"
}

# Show help if no arguments
if [ $# -eq 0 ]; then
    usage
    exit 0
fi

case "$1" in
    bump)
        bump_version "$2" "$3"
        ;;
    tag)
        tag_release
        ;;
    -h|--help|help)
        usage
        ;;
    patch|minor|major|custom)
        print_error "This script now has two steps. Did you mean: $0 bump $*"
        echo ""
        usage
        exit 1
        ;;
    *)
        print_error "Unknown command: $1"
        echo ""
        usage
        exit 1
        ;;
esac

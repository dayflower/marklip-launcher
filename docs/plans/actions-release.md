# Implementation Plan: GitHub Actions Release Workflow

## Overview

Implement automated GitHub Releases creation for marklip-launcher using GitHub Actions. The workflow will trigger on version tags (pattern: `v[0-9]+.[0-9]+.[0-9]+`), build the macOS App Bundle, create distributable archives, and publish releases with proper installation instructions including the required `xattr -cr` command for ad-hoc signed applications.

## Context

- **Project**: macOS status bar application written in Swift
- **Build System**: Swift Package Manager + Makefile + custom shell script
- **Output**: `.build/release/Marklip Launcher.app` (macOS App Bundle)
- **Current Version**: 0.1.0 (in Resources/Info.plist)
- **Code Signing**: Ad-hoc signing (no Apple Developer ID)
- **External Dependency**: marklip command (installed via Homebrew)

## Implementation Tasks

### Task 0: Copy Plan to Project Documentation

**File**: `docs/plans/actions-release.md`

Copy this implementation plan to the project's documentation directory for future reference:

1. Create `docs/plans/` directory if it doesn't exist
2. Copy this plan file to `docs/plans/actions-release.md`
3. This preserves the planning documentation in the repository

### Task 1: Create GitHub Actions Workflow

**File**: `.github/workflows/release.yml`

Create a GitHub Actions workflow with the following structure:

**Trigger Configuration**:
- Trigger on tags matching pattern `v[0-9]+.[0-9]+.[0-9]+`
- Use `macos-latest` runner
- Set `permissions: contents: write` for creating releases

**Build Steps**:
1. Checkout repository
2. Display Swift version (verify environment)
3. Extract version from tag (e.g., `v0.1.0` → `0.1.0`)
4. Validate version consistency between tag and `Resources/Info.plist`
5. Build App Bundle using `make build`
6. Verify build output (check App Bundle, executable, Info.plist existence)
7. Create zip archive: `Marklip-Launcher-{version}.zip`
8. Generate SHA256 checksum file
9. Generate release notes (from git commits since previous tag)
10. Create GitHub Release with artifacts and detailed installation instructions

**Key Features**:
- Version validation (fail if Info.plist version ≠ tag version)
- Comprehensive build verification
- Automatic release notes generation
- Include installation instructions in release body
- Emphasize `xattr -cr` requirement with explanation

**Dependencies**:
- `softprops/action-gh-release@v2` - for creating releases
- Standard macOS tools: `swift`, `PlistBuddy`, `shasum`, `zip`

### Task 2: Update README.md

**File**: README.md

Add a new "Installation" section before the "Building" section with two options:

**Option 1: Download from GitHub Releases (Recommended)**:
1. Download latest release zip from GitHub Releases page
2. Verify download with SHA256 checksum (optional)
3. Extract archive
4. **IMPORTANT**: Remove quarantine attributes using `xattr -cr "Marklip Launcher.app"`
5. Move to ~/Applications
6. Run the application

**Why `xattr -cr` is Required**:
- App uses ad-hoc code signing (no Apple Developer ID)
- macOS Gatekeeper applies quarantine attributes to downloaded files
- Command removes quarantine attributes to allow execution
- Security note: Only do this for apps from trusted sources

**Option 2: Build from Source**:
- Redirect to existing Building section

**Restructuring**:
- Rename existing "Installation" section to "Installing from Source Build"
- Move it after "Building" section
- Update section references as needed

### Task 3: Test the Workflow

Before creating the first official release:

1. **Syntax Validation**:
   - Validate YAML syntax using `actionlint` or similar tools

2. **Test Run**:
   - Create test tag: `git tag v0.0.1-test`
   - Push tag: `git push origin v0.0.1-test`
   - Monitor GitHub Actions execution
   - Verify release creation and artifacts

3. **Artifact Verification**:
   - Download the zip archive
   - Verify SHA256 checksum
   - Extract and run `xattr -cr "Marklip Launcher.app"`
   - Test application functionality

4. **Cleanup**:
   - Delete test release from GitHub
   - Delete test tag: `git tag -d v0.0.1-test && git push origin :refs/tags/v0.0.1-test`

### Task 4: Create First Official Release

Once testing is successful:

1. Verify `Resources/Info.plist` version is `0.1.0`
2. Commit workflow and README changes
3. Create tag: `git tag v0.1.0`
4. Push tag: `git push origin v0.1.0`
5. Monitor GitHub Actions workflow
6. Review and enhance release notes if needed
7. Verify release artifacts

## Version Management Strategy

**Single Source of Truth**: `Resources/Info.plist` (`CFBundleShortVersionString`)

**Release Process**:
1. Update version in `Resources/Info.plist`
2. Commit: `git commit -m "Bump version to X.Y.Z"`
3. Create tag: `git tag vX.Y.Z`
4. Push tag: `git push origin vX.Y.Z`
5. GitHub Actions automatically creates release

**Version Validation**:
- Workflow validates Info.plist version matches tag version
- Build fails if versions mismatch
- Prevents accidental version inconsistencies

**Versioning Convention**:
- Format: `MAJOR.MINOR.PATCH` (semantic versioning)
- Tag format: `vMAJOR.MINOR.PATCH` (e.g., `v0.1.0`)

## Critical Files

1. **`.github/workflows/release.yml`** (create)
   - Complete GitHub Actions workflow definition
   - Includes build, validation, and release creation steps

2. **README.md** (update)
   - Add GitHub Releases installation section
   - Document `xattr -cr` requirement and explanation
   - Restructure existing installation instructions

3. **Resources/Info.plist** (reference)
   - Source of truth for version numbers
   - Update before each release

## Potential Issues and Solutions

### Issue 1: Version Mismatch
**Problem**: Info.plist version doesn't match tag
**Solution**: Workflow validation step fails build early
**Prevention**: Document release process clearly

### Issue 2: App Won't Launch After Download
**Problem**: User forgets `xattr -cr` command
**Solution**: Emphasize in README and release notes
**Mitigation**: Use "IMPORTANT" markers and explain why it's needed

### Issue 3: marklip Dependency Missing
**Problem**: App requires external marklip command
**Solution**: Clear documentation in Prerequisites section
**Already addressed**: README includes Homebrew installation instructions

### Issue 4: Icon Generation Failure
**Problem**: `Scripts/bundle-app.sh` fails if icon source missing
**Current status**: Icon files exist, no issue expected
**Safeguard**: Build verification step catches failures

## Verification Steps

After implementation, verify:

1. **Workflow Syntax**:
   - YAML is valid
   - All required permissions are set
   - Action versions are current

2. **Build Process**:
   - `make build` succeeds on GitHub Actions runner
   - App Bundle structure is correct
   - Code signing completes successfully

3. **Release Creation**:
   - Release is created automatically
   - Artifacts are attached (zip + checksum)
   - Release notes are generated correctly

4. **End-to-End Installation**:
   - Download from GitHub Releases
   - Follow README instructions
   - Verify app launches and functions correctly
   - Test marklip integration (Auto, to-html, to-md)

5. **Documentation**:
   - README installation instructions are clear
   - `xattr -cr` explanation is understandable
   - Links to releases page work correctly

## Future Enhancements

Potential improvements for future iterations:

1. **CHANGELOG.md**: Maintain structured changelog for better release notes
2. **Homebrew Cask**: Create cask for `brew install` support
3. **Notarization**: Obtain Apple Developer ID to eliminate `xattr` requirement
4. **Automated Version Bumping**: Auto-increment versions from commit messages
5. **Pre-release Builds**: Create draft releases for testing

## Success Criteria

Implementation is complete when:

- [ ] Plan copied to `docs/plans/actions-release.md`
- [ ] Workflow file created and committed
- [ ] README updated with GitHub Releases installation section
- [ ] Test tag successfully creates a release
- [ ] Downloaded app works after following README instructions
- [ ] First official release (v0.1.0) is published
- [ ] Documentation is clear and accurate

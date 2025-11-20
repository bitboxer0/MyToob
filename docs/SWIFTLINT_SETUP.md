# SwiftLint Xcode Integration Guide

This guide explains how to integrate SwiftLint as an Xcode build phase to enforce code quality automatically.

## Prerequisites

- SwiftLint installed via Homebrew: `brew install swiftlint`
- swift-format installed via Homebrew: `brew install swift-format`

## Xcode Build Phase Setup

### Adding SwiftLint Build Phase

1. **Open the Xcode Project**
   - Open `MyToob.xcodeproj` in Xcode

2. **Select the Target**
   - In the Project Navigator, click on the `MyToob` project (top of the file list)
   - In the main editor, select the `MyToob` app target from the TARGETS list

3. **Add New Run Script Phase**
   - Click the `Build Phases` tab
   - Click the `+` button at the top left of the Build Phases section
   - Select `New Run Script Phase`

4. **Configure the Run Script Phase**
   - **Name**: Rename the phase to "Run SwiftLint" (double-click on "Run Script")
   - **Shell**: `/bin/sh`
   - **Script**: Add the following script:

   ```bash
   # SwiftLint - Code Quality Enforcement
   if [[ "$(uname -m)" == arm64 ]]; then
       export PATH="/opt/homebrew/bin:$PATH"
   fi

   if which swiftlint > /dev/null; then
     swiftlint
   else
     echo "warning: SwiftLint not installed, install with 'brew install swiftlint'"
   fi
   ```

5. **Position the Build Phase**
   - Drag the "Run SwiftLint" phase to position it **before** the "Compile Sources" phase
   - This ensures linting happens before compilation

6. **Configure Build Phase Options**
   - Check "Based on dependency analysis" to skip when no files changed (optional for faster builds)
   - Leave "Show environment variables in build log" unchecked
   - Input Files: (leave empty for now)
   - Output Files: (leave empty for now)

### Adding swift-format Build Phase (Optional)

For automatic formatting during builds (not recommended as it modifies files):

1. Add another "New Run Script Phase"
2. Name it "Run swift-format (Check Only)"
3. Add this script:

   ```bash
   # swift-format - Code Formatting Check
   if [[ "$(uname -m)" == arm64 ]]; then
       export PATH="/opt/homebrew/bin:$PATH"
   fi

   if which swift-format > /dev/null; then
     # Only check, don't auto-format during builds
     swift-format lint --recursive MyToob/
   else
     echo "warning: swift-format not installed, install with 'brew install swift-format'"
   fi
   ```

4. Position it before "Compile Sources"

## Verification

### Test the SwiftLint Build Phase

1. **Build the Project**: Press `Cmd+B`
2. **Check Build Output**: You should see SwiftLint running in the build log
3. **Verify Errors/Warnings**: SwiftLint violations will appear in the Issues Navigator

### Test Custom Compliance Rules

Create a test file with intentional violations:

```swift
// TestViolations.swift
import Foundation

class TestViolations {
  func testGoogleVideoURL() {
    // This should trigger an ERROR
    let badURL = "https://googlevideo.com/videoplayback"
    print(badURL)
  }
  
  func testHardcodedAPIKey() {
    // This should trigger an ERROR
    let apiKey = "AIzaSyABCDEF1234567890ABCDEFGHIJK"
    print(apiKey)
  }
  
  func testForceTry() {
    // This should trigger an ERROR (outside tests)
    let data = try! JSONEncoder().encode(["test": "value"])
    print(data)
  }
}
```

**Expected Results:**
- Build should **FAIL** with SwiftLint errors
- Errors shown in Issues Navigator for each violation
- Click on error to navigate to the offending line

### Disable SwiftLint for Specific Files/Lines

If you need to temporarily disable SwiftLint for specific cases:

```swift
// Disable for entire file
// swiftlint:disable all

// Disable specific rule for file
// swiftlint:disable force_cast

// Disable for next line only
// swiftlint:disable:next force_cast
let value = dict["key"] as! String

// Disable for previous line
let value = dict["key"] as! String
// swiftlint:disable:previous force_cast

// Re-enable rules
// swiftlint:enable force_cast
```

**Note**: Use sparingly and only when absolutely necessary. All disables should have comments explaining why.

## Troubleshooting

### SwiftLint Not Found

**Error**: `warning: SwiftLint not installed`

**Solution**:
```bash
# Install SwiftLint
brew install swiftlint

# Verify installation
which swiftlint  # Should output: /opt/homebrew/bin/swiftlint
swiftlint version
```

### Build Phase Not Running

**Symptoms**: SwiftLint doesn't run during builds

**Solutions**:
1. Ensure "Run SwiftLint" phase is **before** "Compile Sources"
2. Check the build log (View → Navigators → Report Navigator)
3. Verify the script has correct permissions
4. Try cleaning the build folder: `Cmd+Shift+K`

### Custom Rules Not Working

**Symptoms**: Custom compliance rules don't trigger

**Solutions**:
1. Verify `.swiftlint.yml` is in the project root directory
2. Check YAML syntax: `swiftlint lint --config .swiftlint.yml`
3. Ensure `custom_rules:` section is properly formatted
4. Test rules manually: `swiftlint lint --path <file>`

### Too Many Warnings

**Symptoms**: Build output cluttered with warnings

**Solutions**:
1. Fix critical errors first (marked with `error:`)
2. Disable specific rules in `.swiftlint.yml` if not relevant
3. Use `--quiet` flag for less verbose output (in CI only)
4. Gradually increase strictness rather than all at once

## CI/CD Integration

For GitHub Actions or other CI systems:

```yaml
# .github/workflows/swiftlint.yml
name: SwiftLint

on: [push, pull_request]

jobs:
  swiftlint:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install SwiftLint
        run: brew install swiftlint
      - name: Run SwiftLint
        run: swiftlint lint --strict --reporter github-actions-logging
```

For Danger integration (PR checks):

```ruby
# Dangerfile
swiftlint.config_file = '.swiftlint.yml'
swiftlint.lint_files inline_mode: true
```

## Best Practices

1. **Run Before Committing**: Always run `swiftlint` locally before pushing
2. **Auto-Fix When Possible**: Use `swiftlint --fix` to auto-correct simple issues
3. **Review Custom Rules**: Periodically review custom rules for relevance
4. **Don't Disable Blindly**: If a rule triggers, understand why before disabling
5. **Keep Updated**: Update SwiftLint regularly: `brew upgrade swiftlint`
6. **Team Alignment**: Ensure entire team uses same SwiftLint version

## Configuration Files

- **`.swiftlint.yml`**: Main SwiftLint configuration
- **`.swift-format`**: swift-format configuration  
- **`Dangerfile`**: Danger PR automation rules
- **`README.md`**: Quick reference for setup

## Support

For issues or questions:
- Review this guide
- Check SwiftLint documentation: https://realm.github.io/SwiftLint/
- Review project coding standards: `docs/architecture/coding-standards.md`
- Consult team leads for policy exceptions

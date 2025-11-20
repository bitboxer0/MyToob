# Known Issues

**Last Updated:** 2025-11-19

## Test Failures (Discovered During Story 1.3 Validation)

The following test failures were discovered when validating the CI/CD pipeline on GitHub Actions. These are product issues, not CI infrastructure problems.

### 1. LocalFileImportUITests.testImportLocalFilesButtonAccessibility

**Status:** ❌ Failing
**Severity:** Medium
**Component:** UI Tests - Local File Import

**Error:**
```
XCTAssertNotNil failed: throwing "NSUnknownKeyException: [<XCUIElement 0x6000007636f0> valueForUndefinedKey:]: this class is not key value coding-compliant for the key accessibilityHint."
```

**Root Cause:** `accessibilityHint` is an iOS-only API, not available on macOS.

**Location:** `MyToobUITests/LocalFileImportUITests.swift:50`

**Impact:** UI accessibility test cannot run on macOS

**Remediation:**
- Option 1: Remove accessibilityHint test for macOS
- Option 2: Use conditional compilation (#if os(macOS))
- Option 3: Use macOS-specific accessibility properties (accessibilityLabel, accessibilityHelp)

**Assigned To:** TBD
**Priority:** Medium (does not block functionality, only test coverage)

---

### 2. NoteTests.cascadeDelete()

**Status:** ❌ Failing
**Severity:** High
**Component:** Model Tests - Note Entity

**Error:** Details not yet investigated

**Location:** `MyToobTests/Models/NoteTests.swift`

**Impact:** Cascade deletion of notes when parent VideoItem is deleted may not be working correctly

**Remediation:** Investigate SwiftData cascade delete relationship configuration

**Assigned To:** TBD
**Priority:** High (data integrity issue)

---

### 3. LocalFileImportServiceTests.testExtractMetadataFromValidVideo()

**Status:** ❌ Failing
**Severity:** High
**Component:** Service Tests - Local File Import

**Error:** Details not yet investigated

**Location:** `MyToobTests/Services/LocalFileImportServiceTests.swift`

**Impact:** Metadata extraction from local video files may not be working correctly

**Remediation:** Investigate AVAsset metadata extraction logic

**Assigned To:** TBD
**Priority:** High (core feature functionality)

---

### 4. LocalFileImportServiceTests.testResolveSecurityScopedBookmark()

**Status:** ❌ Failing
**Severity:** High
**Component:** Service Tests - Local File Import

**Error:** Details not yet investigated

**Location:** `MyToobTests/Services/LocalFileImportServiceTests.swift`

**Impact:** Security-scoped bookmark resolution may not be working, which would prevent persistent file access

**Remediation:** Investigate sandbox entitlements and bookmark data handling

**Assigned To:** TBD
**Priority:** High (required for persistent file access)

---

## Resolution Tracking

**Total Issues:** 4
**High Severity:** 3
**Medium Severity:** 1

**Next Steps:**
1. Triage and assign issues to developers
2. Create individual bug fix stories
3. Prioritize based on severity and impact
4. Update this document as issues are resolved

---

**Related Stories:**
- Story 1.3 (GitHub CI/CD Pipeline) - Where issues were discovered
- Story 1.4 (SwiftData Core Models) - Related to cascade delete issue
- Story 5.1 (Local File Import) - Related to metadata and bookmark issues

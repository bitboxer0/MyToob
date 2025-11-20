# Dangerfile for MyToob
# Automated PR checks for compliance, security, and code quality

# Check for PR description
if github.pr_body.length < 10
  fail("Please provide a detailed PR description explaining what changes were made and why.")
end

# Check for linked issue
if !github.pr_body.include?("#") && !github.pr_body.include?("http")
  warn("Please link related issues or stories in the PR description.")
end

# Check for large PR
if git.lines_of_code > 500
  warn("This PR has #{git.lines_of_code} lines of code. Consider breaking it into smaller PRs for easier review.")
end

# Check for WIP or Draft PRs
if github.pr_title.include?("WIP") || github.pr_draft
  warn("This PR is marked as WIP/Draft. Remove the WIP tag when ready for review.")
end

# CRITICAL: Check for YouTube ToS violations
policy_violation_keywords = [
  "googlevideo.com",
  "download.*youtube",
  "cache.*youtube.*stream",
  "extract.*stream",
  "ad.*block",
  "skip.*ad"
]

policy_violation_keywords.each do |keyword|
  if git.diff.match(/#{keyword}/i)
    fail("CRITICAL: Potential YouTube ToS violation detected. Found pattern: '#{keyword}'. Review compliance requirements.")
  end
end

# SECURITY: Check for hardcoded secrets
security_patterns = [
  /api[_-]?key\s*=\s*["'][a-zA-Z0-9]{20,}["']/i,
  /secret\s*=\s*["'][a-zA-Z0-9]{16,}["']/i,
  /token\s*=\s*["'][a-zA-Z0-9]{16,}["']/i,
  /password\s*=\s*["'][^"']+["']/i
]

security_patterns.each do |pattern|
  if git.diff.match(pattern)
    fail("SECURITY: Potential hardcoded secret detected. Never commit secrets to version control.")
  end
end

# Check for changes to security-sensitive files
security_sensitive_files = [
  "KeychainService.swift",
  "Configuration.swift",
  "OAuthService.swift",
  "YouTubeService.swift",
  "MyToob.entitlements"
]

modified_security_files = git.modified_files.select { |file| 
  security_sensitive_files.any? { |sensitive| file.include?(sensitive) }
}

if modified_security_files.any?
  warn("⚠️ This PR modifies security-sensitive files: #{modified_security_files.join(', ')}. Extra review required.")
end

# Check for changes to SwiftData models
swiftdata_model_files = git.modified_files.select { |file| 
  file.include?("Models/") && file.end_with?(".swift")
}

if swiftdata_model_files.any?
  warn("📊 This PR modifies SwiftData models: #{swiftdata_model_files.join(', ')}. Ensure migration plan is documented.")
end

# Check for new dependencies
if git.modified_files.include?("MyToob.xcodeproj/project.pbxproj")
  warn("📦 Xcode project file modified. If adding new dependencies, ensure they are documented and reviewed.")
end

# Check for test coverage
has_app_changes = git.modified_files.any? { |file| 
  file.start_with?("MyToob/") && file.end_with?(".swift") && !file.include?("Tests")
}

has_test_changes = git.modified_files.any? { |file| 
  file.include?("Tests") && file.end_with?(".swift")
}

if has_app_changes && !has_test_changes
  warn("⚠️ This PR modifies app code but doesn't include test changes. Consider adding tests.")
end

# Check for UI changes without screenshots
has_ui_changes = git.modified_files.any? { |file| 
  file.end_with?("View.swift") || file.include?("UI/")
}

if has_ui_changes && !github.pr_body.match?(/!\[.*\]\(.*\)/)
  warn("📸 This PR includes UI changes. Consider adding screenshots to the description.")
end

# Check for TODO comments in new code
added_todos = git.diff.select { |line| line.start_with?("+") && line.include?("TODO") }
if added_todos.any?
  message("📝 This PR adds #{added_todos.count} TODO comment(s). Ensure they are tracked in issues.")
end

# Check SwiftLint results
swiftlint.config_file = '.swiftlint.yml'
swiftlint.lint_files inline_mode: true

# Success message
if status_report[:errors].empty? && status_report[:warnings].empty?
  message("✅ All automated checks passed! Great job!")
end

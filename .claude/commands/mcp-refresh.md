# MCP Tools Reference

Display all available MCP tools for this project and when to use them.

## Code Intelligence & Navigation

### Serena (`mcp__serena__*`)
**Primary tool for semantic code understanding - ALWAYS use first!**

- `get_symbols_overview` - Get file overview (ALWAYS start here, never read full file first)
- `find_symbol` - Find classes/methods/properties by name path
- `find_referencing_symbols` - Find all references to a symbol
- `search_for_pattern` - Search code with regex patterns
- `replace_symbol_body` - Replace method/class implementation
- `insert_after_symbol` - Add new code after a symbol
- `rename_symbol` - Rename across entire codebase

**Critical Rule:** NEVER read entire files without checking `get_symbols_overview` first!

---

## Build & Test

### XcodeMCP (`mcp__xcodemcp__*`)
**Use instead of raw xcodebuild commands!**

- `xcode_build` - Build the app (can take minutes)
- `xcode_test` - Run tests (can take minutes to hours)
- `xcode_clean` - Clean build folder
- `xcresult_browse` - Analyze test failures with screenshots
- `xcresult_get_screenshot` - Extract failure screenshots
- `find_xcresults` - Find all test result bundles

---

## Apple Documentation

### Apple Docs MCP (`mcp__apple-docs-mcp__*`)
**Essential for iOS/macOS development - use before WebSearch!**

- `search_apple_docs` - Search Apple Developer Documentation
- `get_apple_doc_content` - Get full API documentation
- `list_technologies` - Browse all frameworks by category
- `search_framework_symbols` - Explore framework APIs
- `search_wwdc_content` - Search WWDC video transcripts
- `get_wwdc_video` - Get full WWDC session with code

---

## Context Management

### RepoPrompt (`mcp__RepoPrompt__*`)
**Smart multi-file context - auto-adds related files!**

- `manage_selection` - Select files for context (auto-adds codemaps)
- `get_code_structure` - Get API signatures without file bodies
- `file_search` - Search across codebase
- `get_file_tree` - View directory structure
- `apply_edits` - Apply search/replace or rewrites

---

## File Operations

### Filesystem (`mcp__filesystem__*`)
**Low-level file ops when MCP tools don't cover it**

- `read_text_file` - Read files
- `read_multiple_files` - Read multiple files in parallel
- `write_file` - Write/create files
- `edit_file` - Line-based edits
- `search_files` - Find files by pattern
- `list_directory` - List directory contents

---

## GitHub Research

### OctoCode MCP (`mcp__octocode-mcp__*`)
**Find reference implementations on GitHub**

- `githubSearchRepositories` - Discover repos by topic/keywords
- `githubSearchCode` - Search code in repos
- `githubViewRepoStructure` - Explore directory structure
- `githubGetFileContent` - Read specific files

---

## Memory & Knowledge

### Memory MCP (`mcp__memory-mcp__*`)
**Persistent knowledge graph across sessions**

- `create_entities` - Store architectural decisions
- `create_relations` - Link related concepts
- `search_nodes` - Search knowledge base
- `read_graph` - View entire knowledge graph

---

## Before Every Task Checklist

✅ Check CLAUDE.md for project-specific MCP guidance
✅ Use `serena.get_symbols_overview` before reading files
✅ Use `xcodemcp` tools for build/test instead of bash
✅ Use `apple-docs-mcp` for Apple APIs instead of WebSearch
✅ Use `RepoPrompt.manage_selection` for multi-file context
✅ Use `octocode-mcp` for GitHub examples instead of WebSearch

---

## 🎯 Serena vs RepoPrompt: When to Use Which

**You are working on a macOS app in a large Swift/SwiftUI/AppKit codebase.**

You have TWO high-level MCP servers for code work:

1) **Serena** ("serena") - IDE brain with LSP for symbolic code operations
2) **RepoPrompt** ("RepoPrompt") - Context manager + planning + safe edits

**They are NOT interchangeable!**

### Quick Rules

**Use SERENA when you need:**
- Symbol-level navigation (find types, methods, references)
- Refactoring (API changes, updating call sites)
- Precise edits inside known code
- **Think:** "IDE navigation + structural edits"

**Use REPOPROMPT when you need:**
- Context curation (select files for a feature/bugfix)
- Multi-step planning (architecture changes, new features)
- Safe cross-cutting changes (reviewable diffs)
- **Think:** "Pick files + plan + apply diffs"

### Combo Pattern (Default for Complex Tasks)

1. **RepoPrompt first** - Inspect tree, search, build file selection, plan
2. **Serena next** - Navigate symbols, find references, make precise edits
3. **RepoPrompt again** - Apply multi-file diffs, review changes

### Conflict Resolution

- Task mentions **REFACTOR, RENAME, FIND REFERENCES, UPDATE CALL SITES**? → **Serena**
- Task mentions **PLAN, SELECT FILES, CONTEXT, LARGE EDIT, DIFF**? → **RepoPrompt**
- Big task with both? → Start RepoPrompt (plan) → Serena (edits) → RepoPrompt (diffs)

**Do NOT use both blindly for the same subtask. Choose ONE based on rules above.**

### Safety

- Never do large sweeping edits with Serena alone without planning
- For multi-file/architectural changes: RepoPrompt (plan) → Serena (edit) → tests

---

**For complete documentation, see the "MCP Server Tooling Guide" section in CLAUDE.md**

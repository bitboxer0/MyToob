# Next Steps

## UX Expert Prompt

Now that the PRD is complete, please transition to **UX Expert mode** using the `front-end-spec-tmpl` template. Create a comprehensive front-end specification document for MyToob that details:

- macOS-native SwiftUI component hierarchy
- Screen-by-screen layouts (sidebar, content grid, player view, search, settings)
- Interaction patterns (drag-and-drop, context menus, keyboard shortcuts)
- Visual design system (color palette, typography, iconography)
- Accessibility requirements (VoiceOver labels, focus order, high-contrast)
- YouTube IFrame Player integration details
- AVKit player integration details

Reference this PRD for feature requirements and ensure the front-end spec covers all user-facing interactions described in the epics. Focus on creating a design that feels **native, fast, and intelligent** while maintaining compliance with YouTube policies (no UI overlay of player).

## Architect Prompt

After the front-end specification is complete, transition to **Architect mode** using the `fullstack-architecture-tmpl` template. Create a technical architecture document that defines:

- System architecture diagram (services, data flow, external APIs)
- SwiftData models with relationships and migration strategy
- YouTube integration architecture (OAuth, Data API client, IFrame Player bridge, quota management)
- Core ML pipeline (embedding generation, vector index, clustering, ranking)
- CloudKit sync architecture (conflict resolution, schema mapping)
- Security architecture (Keychain, sandboxing, security-scoped bookmarks)
- Performance optimization strategies (caching, background processing, lazy loading)
- Testing strategy (unit, integration, UI, migration, soak tests)

Reference both the PRD and front-end spec to ensure the architecture supports all features and UI requirements. Highlight compliance enforcement mechanisms (lint rules, policy boundaries) and provide clear implementation guidance for each epic.

---

*This PRD represents the complete product vision for MyToob v1.0. All subsequent development should reference this document to ensure feature completeness and alignment with project goals.*

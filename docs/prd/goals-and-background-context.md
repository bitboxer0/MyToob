# Goals and Background Context

## Goals

- Deliver a **native macOS video organization application** that combines YouTube integration and local file management with on-device AI capabilities
- Achieve **100% compliance** with YouTube Terms of Service and App Store Guidelines to enable successful App Store distribution
- Provide **tangible independent value** beyond a simple wrapper through AI-powered search, clustering, and research tools
- Ensure **privacy-first architecture** where all AI processing happens on-device using Core ML
- Create a **freemium monetization model** with basic features free and Pro tier for advanced AI/research capabilities
- Establish **dual distribution channels**: App Store build (strict compliance) and notarized DMG (power-user features for local files)
- Achieve **performance targets**: P95 search latency <50ms, cold start <2s, smooth playback
- Build **foundation for long-term product evolution** with modular architecture supporting future enhancements

## Background Context

Video content has become a primary medium for learning, research, and knowledge work, yet existing tools fail to provide adequate organization and discovery capabilities. YouTube's web interface offers minimal organizational features beyond basic playlists, while traditional media players lack intelligence and cloud integration. Knowledge workers—researchers, students, content creators—find themselves juggling disconnected tools for viewing, organizing, and annotating video content.

MyToob addresses this gap by providing a native macOS application that unifies YouTube content (accessed via official, compliant APIs) with local video files in a single, intelligently organized interface. By leveraging on-device AI through Core ML, the app offers semantic search, automatic topic clustering, and personalized recommendations while maintaining complete user privacy—no data leaves the device except through user-controlled CloudKit sync.

The compliance-first architecture distinguishes MyToob from "YouTube downloader" apps that violate ToS. By using only the official YouTube IFrame Player for playback and the Data API for metadata, MyToob provides a sustainable, App Store-approved path forward while delivering genuine value through AI organization features that work equally well for YouTube and local content.

## Change Log

| Date | Version | Description | Author |
|------|---------|-------------|--------|
| 2025-11-17 | 1.0 | Initial PRD created from Project Brief and IdeaDoc | BMad Master |
| 2025-11-17 | 1.1 | Added Epic 4: Focus Mode & Distraction Management (7 stories, FR75-FR82) | BMad Master |

---

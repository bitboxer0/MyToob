# Introduction

This document outlines the complete technical architecture for MyToob, a native macOS application built with SwiftUI that combines YouTube integration (via official APIs) with local video file management and on-device AI-powered organization. This architecture ensures compliance with YouTube Terms of Service, App Store Guidelines, and privacy-first principles while delivering high performance and excellent user experience.

## Project Context

**Project Type:** Greenfield native macOS application (macOS 14.0+, Apple Silicon optimized)

**Architectural Philosophy:**
- **Native-First:** Leverage Apple's frameworks (SwiftUI, SwiftData, Core ML, CloudKit, AVKit) for optimal performance and platform integration
- **Privacy-First:** All AI processing on-device; no external data collection
- **Compliance-First:** Strict adherence to YouTube ToS and App Store Guidelines
- **Single-Process:** Monolithic app architecture (no microservices, no backend servers)
- **Platform-Specific:** macOS-only in MVP (potential iOS/iPadOS companion apps post-MVP)

## Change Log

| Date | Version | Description | Author |
|------|---------|-------------|--------|
| 2025-11-17 | 1.0 | Initial architecture document | BMad Master |

---

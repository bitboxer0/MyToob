//
//  NoteTests.swift
//  MyToobTests
//
//  Created by Claude Code (BMad Master) - Story 1.4
//

import Testing
import Foundation
import SwiftData
@testable import MyToob

@Suite("Note Model Tests")
struct NoteTests {

    @Test("Create note without timestamp")
    func createGeneralNote() async throws {
        let note = Note(
            content: "This is a test note in **Markdown** format."
        )

        #expect(!note.noteID.isEmpty)
        #expect(note.content == "This is a test note in **Markdown** format.")
        #expect(note.timestamp == nil)
        #expect(note.videoItem == nil)
        #expect(note.formattedTimestamp == nil)
    }

    @Test("Create note with timestamp")
    func createTimestampedNote() async throws {
        let note = Note(
            content: "Important moment!",
            timestamp: 125.5
        )

        #expect(note.content == "Important moment!")
        #expect(note.timestamp == 125.5)
        #expect(note.formattedTimestamp == "2:05")
    }

    @Test("Formatted timestamp - seconds only")
    func formattedTimestampSeconds() async throws {
        let note = Note(content: "Test", timestamp: 45.0)
        #expect(note.formattedTimestamp == "0:45")
    }

    @Test("Formatted timestamp - minutes and seconds")
    func formattedTimestampMinutesSeconds() async throws {
        let note = Note(content: "Test", timestamp: 185.0)
        #expect(note.formattedTimestamp == "3:05")
    }

    @Test("Formatted timestamp - hours, minutes, seconds")
    func formattedTimestampHours() async throws {
        let note = Note(content: "Test", timestamp: 3725.0) // 1:02:05
        #expect(note.formattedTimestamp == "1:02:05")
    }

    @Test("Update note content")
    func updateNoteContent() async throws {
        let note = Note(content: "Original content")
        let originalUpdatedAt = note.updatedAt

        // Wait a tiny bit to ensure timestamp changes
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        note.update(content: "Updated content")

        #expect(note.content == "Updated content")
        #expect(note.updatedAt > originalUpdatedAt)
    }

    @Test("Update note timestamp")
    func updateNoteTimestamp() async throws {
        let note = Note(content: "Test", timestamp: 100.0)

        note.update(timestamp: 200.0)

        #expect(note.timestamp == 200.0)
        #expect(note.formattedTimestamp == "3:20")
    }

    @Test("Update both content and timestamp")
    func updateBoth() async throws {
        let note = Note(content: "Original", timestamp: 100.0)

        note.update(content: "Updated", timestamp: 200.0)

        #expect(note.content == "Updated")
        #expect(note.timestamp == 200.0)
    }

    @Test("SwiftData persistence")
    func persistNote() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Note.self, VideoItem.self,
            configurations: config
        )
        let context = ModelContext(container)

        let note = Note(
            noteID: "note-001",
            content: "Persistence test note",
            timestamp: 150.0
        )

        context.insert(note)
        try context.save()

        // Fetch back
        let descriptor = FetchDescriptor<Note>(
            predicate: #Predicate { $0.noteID == "note-001" }
        )
        let fetchedNotes = try context.fetch(descriptor)

        #expect(fetchedNotes.count == 1)
        #expect(fetchedNotes.first?.content == "Persistence test note")
        #expect(fetchedNotes.first?.timestamp == 150.0)
    }

    @Test("Note relationship with VideoItem")
    func noteVideoItemRelationship() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Note.self, VideoItem.self,
            configurations: config
        )
        let context = ModelContext(container)

        // Create video item
        let videoItem = VideoItem(
            videoID: "video-001",
            title: "Test Video",
            channelID: nil,
            duration: 300.0
        )
        context.insert(videoItem)

        // Create notes
        let note1 = Note(
            content: "First note",
            timestamp: 50.0,
            videoItem: videoItem
        )
        let note2 = Note(
            content: "Second note",
            timestamp: 100.0,
            videoItem: videoItem
        )

        context.insert(note1)
        context.insert(note2)
        try context.save()

        // Fetch video and verify notes
        let videoDescriptor = FetchDescriptor<VideoItem>(
            predicate: #Predicate { $0.videoID == "video-001" }
        )
        let fetchedVideos = try context.fetch(videoDescriptor)

        #expect(fetchedVideos.count == 1)
        #expect(fetchedVideos.first?.notes?.count == 2)
    }

    @Test("Cascade delete - deleting video deletes notes")
    func cascadeDelete() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Note.self, VideoItem.self,
            configurations: config
        )
        let context = ModelContext(container)

        // Create video with notes
        let videoItem = VideoItem(
            videoID: "video-cascade",
            title: "Cascade Test",
            channelID: nil,
            duration: 300.0
        )
        context.insert(videoItem)

        let note = Note(
            content: "Will be deleted",
            videoItem: videoItem
        )
        context.insert(note)
        try context.save()

        // Delete video
        context.delete(videoItem)
        try context.save()

        // Verify notes are also deleted
        let noteDescriptor = FetchDescriptor<Note>()
        let remainingNotes = try context.fetch(noteDescriptor)
        #expect(remainingNotes.isEmpty)
    }

    @Test("Delete note independently")
    func deleteNoteIndependently() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Note.self, VideoItem.self,
            configurations: config
        )
        let context = ModelContext(container)

        let note = Note(content: "Delete me")
        context.insert(note)
        try context.save()

        // Delete note
        context.delete(note)
        try context.save()

        // Verify deletion
        let descriptor = FetchDescriptor<Note>()
        let notes = try context.fetch(descriptor)
        #expect(notes.isEmpty)
    }
}

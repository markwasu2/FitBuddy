//  FitBuddyMVP.swift
//  Drop this single file into a new Xcode > iOS App (SwiftUI) project.
//  It compiles without external dependencies and demonstrates:
//    • Onboarding input for goal/equipment
//    • TabView navigation (Home, Chatbot, Scanner)
//    • GPT-like chatbot stub that schedules an EventKit workout
//    • Photos‑based calorie scan stub using a hard‑coded lookup table
//  Replace stubs with real API calls + CoreML model when ready.

import SwiftUI
import EventKit
import PhotosUI
import Vision
import CoreML
import GoogleGenerativeAI
import Speech
import AVFoundation
import HealthKit
import Foundation
import CoreData

// MARK: - Data Models (Keep existing models)
struct NutritionEntry: Identifiable, Codable {
    let id = UUID()
    let foodName: String
    let calories: Double
    let macros: MacroNutrients
    let timestamp: Date
    let imageData: Data?
    
    struct MacroNutrients: Codable {
        let protein_g: Double
        let carbs_g: Double
        let fat_g: Double
        let fiber_g: Double
    }
}

struct WorkoutPlan: Identifiable, Codable {
    let id = UUID()
    let name: String
    let type: WorkoutType
    let exercises: [Exercise]
    let duration: TimeInterval
    
    enum WorkoutType: String, Codable, CaseIterable {
        case strength = "Strength"
        case cardio = "Cardio"
        case flexibility = "Flexibility"
        case hiit = "HIIT"
    }
}

struct Exercise: Identifiable, Codable {
    let id = UUID()
    let name: String
    let sets: Int
    let reps: Int
    let weight: Double?
    let duration: TimeInterval?
}

// MARK: - App Entry Point
@main
struct FitBuddyApp: App {
    @StateObject private var healthKitManager = HealthKitManager()
    @StateObject private var profileManager = ProfileManager()
    @StateObject private var workoutPlanManager = WorkoutPlanManager()
    @StateObject private var nutritionViewModel = NutritionViewModel()
    @StateObject private var geminiService = GeminiService()
    @StateObject private var calendarManager = CalendarManager()
    @StateObject private var workoutJournal = WorkoutJournal()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(healthKitManager)
                .environmentObject(profileManager)
                .environmentObject(workoutPlanManager)
                .environmentObject(nutritionViewModel)
                .environmentObject(geminiService)
                .environmentObject(calendarManager)
                .environmentObject(workoutJournal)
                .onAppear {
                    healthKitManager.requestAuthorization()
                }
        }
    }
}

// MARK: - Root Navigation
struct RootView: View {
    @EnvironmentObject var profileManager: ProfileManager
    
    var body: some View {
        if profileManager.isOnboardingComplete {
            MainTabView()
        } else {
            OnboardingView()
                .preferredColorScheme(.light)
        }
    }
}


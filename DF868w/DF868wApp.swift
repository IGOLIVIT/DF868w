//
//  DF868wApp.swift
//  DF868w
//
//  Ledgerly - Personal finance tracker
//

import SwiftUI
import SwiftData

@main
struct DF868wApp: App {
    let container: ModelContainer
    let store: AppStore

    init() {
        do {
            container = try ModelContainer.ledgerlyContainer()
            store = AppStore(modelContext: container.mainContext)
            SeedData.seedIfNeeded(context: container.mainContext)
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
        }
        .modelContainer(container)
    }
}

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppStore.self) private var store
    @Query private var preferences: [Preferences]

    private var showOnboarding: Bool {
        !(preferences.first?.onboardingCompleted ?? false)
    }

    var body: some View {
        Group {
            if showOnboarding {
                OnboardingView()
            } else {
                MainTabView()
            }
        }
        .overlay(alignment: .top) {
            if store.showToast, let message = store.toastMessage {
                ToastView(message: message)
                    .padding(.top, 60)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(100)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: store.showToast)
    }
}

//
//  flash_cardsApp.swift
//  flash_cards
//
//  Created by wada on 2025/02/16.
//

import SwiftUI
import ComposableArchitecture

@main
struct flash_cardsApp: App {
    init() {
        // Initialize Realm migration once when the app launches
        let migration = RealmMigration()
        migration()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(
                store: Store(
                    initialState: Content.State()) {
                        Content()
                    }
            )
        }
    }
}

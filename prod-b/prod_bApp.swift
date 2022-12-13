//
//  prod_bApp.swift
//  prod-b
//
//  Created by Cameron Bennett on 6/24/22.
//

import SwiftUI
import SQLite

@main
struct prod_bApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            initView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

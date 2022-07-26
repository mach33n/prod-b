//
//  prod_bApp.swift
//  prod-b
//
//  Created by Cameron Bennett on 6/24/22.
//

import SwiftUI

@main
struct prod_bApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            PracticeView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

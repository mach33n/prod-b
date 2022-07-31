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
    
    init() {
        do {
            let path = NSSearchPathForDirectoriesInDomains(
                .documentDirectory, .userDomainMask, true
            ).first!
            let db = try Connection("\(path)/db.sqlite3")
            let happyTable = Table("Happy_Sad")
            let id = Expression<String>("id")
            let trackName = Expression<String>("track_name")
            let producerName = Expression<String>("producer_name")
            let audioUrl = Expression<String>("audio_url")
            let happyScore = Expression<Double>("happy_score")
            let aggScore = Expression<Double>("aggressiveness_score")
            
            try db.run(happyTable.create { t in
                t.column(id, primaryKey: true)
                t.column(trackName)
                t.column(producerName)
                t.column(audioUrl, unique: true)
                t.column(happyScore)
                t.column(aggScore)
            })
            
            let insert = happyTable.insert(id <- UUID().asSQL(), trackName <- "AlwaysMind", producerName <- "sample", audioUrl <- "https://firebasestorage.googleapis.com/v0/b/prodb-3f552.appspot.com/o/Always%20on%20my%20Mind.mp3?alt=media&token=f2914a4c-ca8d-4eec-a4fc-2bc9c18e790d", happyScore <- 0.70, aggScore <- 0.55)
            _ = try db.run(insert)
        } catch {
            print(error)
        }
    }

    var body: some Scene {
        WindowGroup {
            PracticeView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

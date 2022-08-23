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
//        do {
//            let path = NSSearchPathForDirectoriesInDomains(
//                .documentDirectory, .userDomainMask, true
//            ).first!
//            let db = try Connection("\(path)/db.sqlite3")
//            let happyTable = Table("Happy_Sad")
//            let id = Expression<String>("id")
//            let trackName = Expression<String>("track_name")
//            let producerName = Expression<String>("producer_name")
//            let audioUrl = Expression<String>("audio_url")
//            let happyScore = Expression<Double>("happy_score")
//            let aggScore = Expression<Double>("aggressiveness_score")
//            
//            let imageTable = Table("ID_Image_Map")
//            let image = Expression<String>("image")
//            
//            // what table to drop and recreate
////            try db.run(happyTable.delete())
////            try db.run(imageTable.delete())
//            
//            
//            
//            try db.run(happyTable.create(ifNotExists: true) { t in
//                t.column(id, primaryKey: true)
//                t.column(trackName)
//                t.column(producerName)
//                t.column(audioUrl, unique: true)
//                t.column(happyScore)
//                t.column(aggScore)
//            })
//
//            try db.run(imageTable.create(ifNotExists: true) { t in
//                t.column(id, primaryKey: true)
//                t.column(image)
//            })
//
//            var entry_id = UUID().asSQL()
//            var insert = happyTable.insert(id <- entry_id, trackName <- "Always on my Mind", producerName <- "sample", audioUrl <- "https://firebasestorage.googleapis.com/v0/b/prodb-3f552.appspot.com/o/tracks%2FAlways%20on%20my%20Mind.mp3?alt=media&token=d10eea18-2259-40b5-9f2e-02310e509a37", happyScore <- 0.70, aggScore <- 0.55)
//            _ = try db.run(insert)
//            insert = imageTable.insert(id <- entry_id, image <- "c")
//            _ = try db.run(insert)
//
//            entry_id = UUID().asSQL()
//            insert = happyTable.insert(id <- entry_id, trackName <- "Ghost Stories 2", producerName <- "sample", audioUrl <- "https://firebasestorage.googleapis.com/v0/b/prodb-3f552.appspot.com/o/tracks%2FGhost%20Stories2.mp3?alt=media&token=8ebe5c99-3f30-43b3-867f-6d00e3bca6f8", happyScore <- 0.65, aggScore <- 0.60)
//            _ = try db.run(insert)
//            insert = imageTable.insert(id <- entry_id, image <- "https://firebasestorage.googleapis.com/v0/b/prodb-3f552.appspot.com/o/cover_art%2FGhost%20Stories2.mp3.jpg?alt=media&token=236371bc-a1e7-4453-983f-0778afe3e438")
//            _ = try db.run(insert)
//
//            entry_id = UUID().asSQL()
//            insert = happyTable.insert(id <- entry_id, trackName <- "Praia Do Amor", producerName <- "sample", audioUrl <- "https://firebasestorage.googleapis.com/v0/b/prodb-3f552.appspot.com/o/tracks%2FPraia%20Do%20Amor.mp3?alt=media&token=41d75cb3-fce0-4a0b-ad0f-11ca1685d3ee", happyScore <- 0.55, aggScore <- 0.60)
//            _ = try db.run(insert)
//            insert = imageTable.insert(id <- entry_id, image <- "https://firebasestorage.googleapis.com/v0/b/prodb-3f552.appspot.com/o/cover_art%2FPraia%20Do%20Amor.mp3.jpg?alt=media&token=97c0b621-ca46-414c-90d6-42e75e312093")
//            _ = try db.run(insert)
//
//            entry_id = UUID().asSQL()
//            insert = happyTable.insert(id <- entry_id, trackName <- "Soul Searchin", producerName <- "sample", audioUrl <- "https://firebasestorage.googleapis.com/v0/b/prodb-3f552.appspot.com/o/tracks%2FSoul%20Searchin.mp3?alt=media&token=2097a44b-0a1a-4aef-971b-3c007f6e61a8", happyScore <- 0.75, aggScore <- 0.90)
//            _ = try db.run(insert)
//            insert = imageTable.insert(id <- entry_id, image <- "https://firebasestorage.googleapis.com/v0/b/prodb-3f552.appspot.com/o/cover_art%2FSoul%20Searchin.mp3.jpg?alt=media&token=0f848c09-975f-4c8d-8fd3-3da910b093e9")
//            _ = try db.run(insert)
//
//            entry_id = UUID().asSQL()
//            insert = happyTable.insert(id <- entry_id, trackName <- "Time", producerName <- "sample", audioUrl <- "https://firebasestorage.googleapis.com/v0/b/prodb-3f552.appspot.com/o/tracks%2FTime.mp3?alt=media&token=0c0a96d4-53e8-49b6-b323-08a956af0ff2", happyScore <- 0.55, aggScore <- 0.70)
//            _ = try db.run(insert)
//            insert = imageTable.insert(id <- entry_id, image <- "https://firebasestorage.googleapis.com/v0/b/prodb-3f552.appspot.com/o/cover_art%2FTime.mp3.jpg?alt=media&token=564b3f5d-aa03-494f-9bd6-9f295d473153")
//            _ = try db.run(insert)
//
//            entry_id = UUID().asSQL()
//            insert = happyTable.insert(id <- entry_id, trackName <- "Day Dreamer", producerName <- "sample", audioUrl <- "https://firebasestorage.googleapis.com/v0/b/prodb-3f552.appspot.com/o/tracks%2Fday%20dreamer.mp3?alt=media&token=4227269a-c6b7-4752-adef-c91a99a8dbc2", happyScore <- 0.35, aggScore <- 0.65)
//            _ = try db.run(insert)
//            insert = imageTable.insert(id <- entry_id, image <- "https://firebasestorage.googleapis.com/v0/b/prodb-3f552.appspot.com/o/cover_art%2Fday%20dreamer.mp3.jpg?alt=media&token=82b1da2a-e9fb-43a0-92fb-408f20e28fcf")
//            _ = try db.run(insert)
//
//        } catch {
//            print(error)
//        }
    }

    var body: some Scene {
        WindowGroup {
            PlayerView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

//
//  Storage.swift
//  prod-b
//
//  Created by Cameron Bennett on 7/30/22.
//

import Foundation
import SQLite

struct DataStore {
    
    func pullStuff() -> String? {
        var retString: String?
        do {
            let path = NSSearchPathForDirectoriesInDomains(
                .documentDirectory, .userDomainMask, true
            ).first!
            let db = try Connection("\(path)/db.sqlite3")
            let happyTable = Table("Happy_Sad")
            let id = Expression<Int64>("id")
            let trackName = Expression<String?>("track_name")
            let producerName = Expression<String>("producer_name")
            let audioUrl = Expression<String>("audio_url")
            let happyScore = Expression<Double>("happy_score")
            let aggScore = Expression<Double>("aggressiveness_score")
            
            for user in try db.prepare(happyTable) {
                print("name: \(user[trackName]), prod: \(user[producerName]), score: \(user[happyScore])")
                retString = user[audioUrl]
                // id: 1, name: Optional("Alice"), email: alice@mac.com
            }
        } catch {
            print(error)
        }
        return retString
    }
}

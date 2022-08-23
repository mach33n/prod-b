//
//  Storage.swift
//  prod-b
//
//  Created by Cameron Bennett on 7/30/22.
//

import Foundation
import SQLite
import MobileCoreServices
import SwiftUI
import AVFoundation
import Collections

struct DataStore {
    
    var db: Connection? = nil
    var table: Table
    var imageTable: Table
    
    // Columns for tables
    let id = Expression<String>("id")
    let trackName = Expression<String?>("track_name")
    let producerName = Expression<String>("producer_name")
    let audioUrl = Expression<String>("audio_url")
    let happyScore = Expression<Double>("happy_score")
    let aggScore = Expression<Double>("aggressiveness_score")
    
    let image = Expression<String>("image")
    
    init(path: String =
         NSSearchPathForDirectoriesInDomains(
        .documentDirectory, .userDomainMask, true).first!
    ) {
        do {
            self.db = try Connection("\(path)/db.sqlite3")
        } catch {
            print("Can't connect to db.")
            print("Reason: \(error)")
        }
        self.table = Table("Happy_Sad")
        self.imageTable = Table("ID_Image_Map")
    }
    
    func pullLocal(cursor: CGPoint = CGPoint(x: 0.0, y: 0.0)) -> (OrderedDictionary<String, SongSquare>, OrderedDictionary<String, SongSquare>) {
        var retLocal: OrderedDictionary<String, SongSquare> = OrderedDictionary<String, SongSquare>()
        var retBuffer: OrderedDictionary<String, SongSquare> = OrderedDictionary<String, SongSquare>()
        do {
            let distFunc: (Expression<Double>, Expression<Double>, Double, Double) -> Expression<Double> = try db!.createFunction("distFunc", { x1, y1, x2, y2 in
                return sqrt(pow(x1-x2, 2) + pow(y1-y2, 2))
            })
            let quad1 = table.filter(happyScore > 0.5).filter(aggScore > 0.5).order(distFunc(happyScore, aggScore, 0.5, 0.5).asc).limit(5)
            //let quad2 = table.filter(happyScore < 0.5).filter(aggScore > 0.5).order(distFunc(happyScore, aggScore, 0.5, 0.5).asc).limit(1)
            //let quad3 = table.filter(happyScore > 0.5).filter(aggScore < 0.5).order(distFunc(happyScore, aggScore, 0.5, 0.5).asc).limit(1)
            //let quad4 = table.filter(happyScore < 0.5).filter(aggScore < 0.5).order(distFunc(happyScore, aggScore, 0.5, 0.5).asc).limit(1)
            
            for row in try db!.prepare(quad1) {
                let imageUrl = Array(try db!.prepare(self.imageTable.select(image).filter(id == row[id])))[0][image]
                print("id: \(row[id]), x: \(row[happyScore]), y: \(row[aggScore]), audioUrl: \(row[audioUrl])")
                retBuffer[row[id]] = SongSquare(key: row[id], x: row[happyScore]*UIScreen.screenWidth, y: row[aggScore]*UIScreen.screenWidth, audioURL: row[audioUrl], trackName: row[trackName] ?? "", producerName: row[producerName], image: imageUrl)
            }
        } catch {
            print(error)
        }
        return (retLocal, retBuffer)
    }
}

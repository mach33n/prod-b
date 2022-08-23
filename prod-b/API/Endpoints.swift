//
//  Endpoints.swift
//  prod-b
//
//  Created by Cameron Bennett on 8/13/22.
//

import Foundation
import SwiftUI

struct SquareReq {
    var axis1: String
    var axis2: String
    var limit: Int
}

struct SquareRes: Decodable {
    var _id: String
    var trackName: String
    var producerName: String
    var audioUrl: URL
    var imageUrl: URL
    var happyScore: CGFloat
    var aggScore: CGFloat
    var waveform: [CGFloat]
}

enum Endpoints: Any {
    static let baseUrl = "http://127.0.0.1:8080"
    case retrieve(SquareReq)
}

extension Endpoints {
    mutating func process() -> URL? {
        switch self {
        case let .retrieve(body):
            return URL(string: Endpoints.baseUrl + "/retrieve") 
        }
    }
}

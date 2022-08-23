//
//  Purchase.swift
//  prod-b
//
//  Created by Cameron Bennett on 8/13/22.
//

import Foundation
import SwiftUI

var desc1 = """
Comes with:
    - 2500 Distribution Copies
    - 5000 Audio Streams
    - 5000 Video Streams
    - No additional commercial usage
Must credit:
"""

struct PurchaseInfo {
    var type: String
    var price: Double
    var description: String
    var artists: String
}

struct SelectionBubble: View {
    
    @Binding var sel: Int
    
    var ind: Int
    
    var purchaseInfo: PurchaseInfo
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 50.0).foregroundColor(Color(.sRGB, white: 0.8, opacity: 0.4))
                VStack {
                    HStack {
                        Text(purchaseInfo.type).frame(maxWidth: 225, alignment: .leading)
                        Text(String(format: "$%.2f", purchaseInfo.price))
                    }.padding(.top, sel == ind ? 20.0 : 15.0).padding(.leading, 20.0).padding(.trailing, 20.0).font(Font(UIFont(name: "Arial-BoldMT", size: 15.0)!))
                Spacer()
                if sel == ind {
                    Text(purchaseInfo.description).frame(maxWidth: 225, alignment: .leading).font(Font(UIFont(name: "GillSans", size: 15.0)!))
                    Text("\(purchaseInfo.artists)")
                    Spacer()
                    Button("Purchase") {
                        print("Here")
                    }
                    .frame(maxWidth: 125, maxHeight: 30)
                    .foregroundColor(.white).background {
                        RoundedRectangle(cornerRadius: 25.0).foregroundColor(Color(.sRGB, white: 0.8, opacity: 0.5))
                    }
                    Spacer()
                }
            }
        }
        .frame(height: sel == ind ? 250 : 50)
        .onTapGesture {
            self.sel = ind
        }
    }
}

struct PurchaseView: View {
    
    @State var index: Int = 0
    private var square = SongSquare.current
    
    var cellInfo: [PurchaseInfo] = [
        PurchaseInfo(type: "MP3 Leasing Rights", price: 35.00, description: desc1, artists: "Sample"),
        PurchaseInfo(type: "MP3 Leasing Rights 2", price: 35.00, description: desc1, artists: "Sample"),
        PurchaseInfo(type: "MP3 Leasing Rights 3", price: 35.00, description: desc1, artists: "Sample"),
        PurchaseInfo(type: "MP3 Leasing Rights 4", price: 35.00, description: desc1, artists: "Sample")
    ]
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 50.0).foregroundColor(square?.avgColor).shadow(radius: 20.0)
            VStack {
                Text("Rights Options").font(Font(UIFont(name: "Helvetica-Bold", size: 25.0)!)).frame(alignment: .top).padding(.top)
                Text(square?.trackName ?? "No Track").font(Font(UIFont(name: "GillSans", size: 20.0)!)).frame(alignment: .top)
                Text("\(square!.producerName)").font(Font(UIFont(name: "GillSans", size: 20.0)!))
                VStack {
                    ForEach(cellInfo.indices) { ind in
                        SelectionBubble(sel: $index, ind: ind, purchaseInfo: cellInfo[ind]).shadow(color: Color(.sRGB, white: 0.3, opacity: 0.9), radius: 7, x: -5.0, y: -5.0).shadow(color: Color(.sRGB, white: 0.0, opacity: 0.9), radius: 7, x: 5.0, y: 5.0)
                    }
                }.frame(width: 300, height: 7*525/8)
            }
        }.frame(width: 350, height: 525, alignment: .center)
    }
}

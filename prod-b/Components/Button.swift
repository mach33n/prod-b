//
//  Button.swift
//  prod-b
//
//  Created by Cameron Bennett on 8/9/22.
//

import SwiftUI

struct PlayerButton: View {
    var frameDim: CGSize
    var imgName: String
    var imgScale: Double = 2/3
    var selectable: Bool = false
    var darkBack: Bool = false
    @State private var selected: Bool = false
    
    var rotate: Bool = false
    var handler: (() -> ())?
    
    var body: some View {
        Button {
            if handler != nil {
                handler!()
            }
            if selectable {
                selected.toggle()
            }
        } label: {
            ZStack {
                Circle().foregroundColor(Color(.sRGB, white: 0.15, opacity: 0.90)).frame(width: frameDim.width, height: frameDim.height, alignment: .center).shadow(color: Color(.sRGB, white: 0.3, opacity: 0.9), radius: 7, x: -5.0, y: -5.0).shadow(color: Color(.sRGB, white: 0.0, opacity: 0.9), radius: 7, x: 5.0, y: 5.0)
                Circle().foregroundColor(self.darkBack ? Color(.sRGB, red: 63/255, green: 55/255, blue: 86/255, opacity: 1.0) : .indigo).frame(width: frameDim.width * 7/9, height: frameDim.height * 7/9, alignment: .center).shadow(color: Color(.sRGB, white: 0.1, opacity: 0.9), radius: 7, x: 0.0, y: 0.0)
                if self.rotate {
                    Image(imgName).resizable().frame(width: frameDim.width * imgScale, height: frameDim.height * imgScale, alignment: .center).rotationEffect(.degrees(180)).colorInvert().shadow(color: Color(.sRGBLinear, white: 0.0, opacity: 1.0), radius: 18, x: 15.0, y: 15.0).shadow(color: Color(.sRGBLinear, white: 0.0, opacity: 1.0), radius: 18, x: 15.0, y: 15.0)
                } else {
                    Image(imgName).resizable().frame(width: frameDim.width * imgScale, height: frameDim.height * imgScale, alignment: .center).colorInvert().colorMultiply(self.selected ? Color(.sRGB, red: 145/255, green: 121/255, blue: 256/255, opacity: 1.0) : .white).shadow(color: Color(.sRGBLinear, white: 0.0, opacity: 1.0), radius: 18, x: 15.0, y: 15.0).shadow(color: Color(.sRGBLinear, white: 0.0, opacity: 1.0), radius: 18, x: 15.0, y: 15.0)
                }
            }
        }.frame(width: frameDim.width, height: frameDim.height, alignment: .center)
    }
}

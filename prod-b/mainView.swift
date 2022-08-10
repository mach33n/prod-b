//
//  File.swift
//  prod-b
//
//  Created by Cameron Bennett on 8/3/22.
//

import SwiftUI
import CoreData
import simd
import Combine
import Swift
import AVFoundation

protocol ContainerView: View {
    associatedtype Content
    init(content: @escaping () -> Content)
}

struct mainView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>
    
    @State var location = CGPoint.zero
    
    var body: some View {
        ZStack {
            VStack {
                Text("Coordinates: (\(location.x), \(location.y))").foregroundColor(.blue).font(.title3)
                HStack(alignment: .center, spacing: 0) {
                    HStack {
                        Image("home").colorInvert()
                        Text("Your Feed").font(.largeTitle)
                    }
                    .frame(width: UIScreen.screenWidth, height: 100, alignment: .center)
                    HStack {
                        Image("user").colorInvert()
                        Text("Profile")
                    }
                    .frame(width: UIScreen.screenWidth, height: 100, alignment: .center)
                    HStack {
                        Image("settings").colorInvert()
                        Text("Options")
                    }
                    .frame(width: UIScreen.screenWidth, height: 100, alignment: .center)
                }
                .frame(width: UIScreen.screenWidth, height: 100, alignment: .center)
                .modifier(ScrollingStackSnap(numElements: 3, direction: .horizontal, sensitivity: 0.1))
                .font(.title)
                .foregroundColor(.white)
            }
            VStack {
                RoundedRectangle(cornerRadius: 5.0 / 2.0)
                    .frame(width: 40, height: 5.0)
                    .foregroundColor(.blue)
                    .offset(x: 0.0, y: 20.0)
                Rectangle()
                    .cornerRadius(25.0)
                    .frame(width: UIScreen.screenWidth, height: UIScreen.screenHeight, alignment: .center)
            }
            .modifier(ScrollingStackSnap(numElements: 2, direction: .vertical, fullSize: UIScreen.screenHeight/2, debug: true))
            .coordinateSpace(name: "mainView")
            .foregroundColor(.gray)
            .opacity(0.6)
            .overlay(dot)
            
        }
        .background(
            LinearGradient(gradient: Gradient(stops: [Gradient.Stop(color: .orange, location: 0), Gradient.Stop(color: .black, location: 0.2)]), startPoint: .top, endPoint: .bottom)
        )
    }
    
    var dot: some View {
        Circle()
            .frame(width: 25, height: 25, alignment: .center)
            .offset(x: location.x, y: location.y)
            .gesture(drag)
            .padding(5)
            .foregroundColor(.blue)
    }
    
    var drag: some Gesture {
        DragGesture(minimumDistance: 0.1, coordinateSpace: .named("mainView"))
            .onChanged { newLoc in
                location = newLoc.location
            }
    }
}

enum orientation {
    case horizontal
    case vertical
}

struct ScrollingStackSnap: ViewModifier {
    
    @State private var offset: CGFloat
    @State private var markers: [debug_pos]
    
    private var debug: Bool
    private var contract: CGFloat
    private var initOffset: CGFloat
    private var direction: orientation
    private var fullSize: CGFloat
    private var numElements: Int
    private var sensitivity: CGFloat
    
    public init(numElements: Int, direction: orientation, fullSize: CGFloat = 0.0, initOffset: CGFloat = 0.0, sensitivity: CGFloat = 1.0, contract: CGFloat = 1.0, debug: Bool = false) {
        self.contract = contract
        self.direction = direction
        self.initOffset = initOffset
        if fullSize == 0.0 {
            self.fullSize = direction == .horizontal ? UIScreen.screenWidth : UIScreen.screenHeight
        } else {
            self.fullSize = fullSize
        }
        self.offset = self.fullSize + self.initOffset
        self.numElements = numElements
        self.sensitivity = sensitivity
        self.debug = debug
        self.markers = []
    }
    
    func body(content: Content) -> some View {
        content
            .offset(x: self.direction == .horizontal ? offset : 0.0, y: self.direction == .vertical ? offset : 0.0)
            .gesture(
                DragGesture()
                    .onChanged { offsetChange in
                        let difference = self.direction == .horizontal ? offsetChange.translation.width : offsetChange.translation.height
                        let adjustment = difference * self.sensitivity * self.contract + self.initOffset
                        if offset < self.fullSize && difference > 0 {
                            if abs(adjustment) < self.fullSize * self.contract - (offset + self.initOffset) {
                                offset += adjustment
                            } else {
                                offset = (self.fullSize *  self.contract) + self.initOffset
                            }
                        } else if offset > -self.fullSize && difference < 0 {
                            if abs(adjustment) + self.initOffset < offset - (self.initOffset - self.fullSize * self.contract) {
                                offset += adjustment
                            } else {
                                offset = -self.fullSize + self.initOffset
                            }
                        }
                    }
                    .onEnded { offsetChange in
                        withAnimation {
                            offset = minDist(main: offset, numElements: self.numElements, fullSize: self.fullSize, initOffset: self.initOffset, contract: self.contract, debug: self.debug)
                        }
                    })
            .overlay(debug_markers)
    }
    
    struct debug_pos {
        let debug_id = UUID()
        let num: Int
        let pos: CGFloat
    }
    
    var debug_markers: some View {
        ForEach(self.markers, id: \.debug_id) { pos in
            Text("Marker number \(pos.num)")
            RoundedRectangle(cornerRadius: 1.0)
                .frame(width: UIScreen.screenWidth, height: 50, alignment: .center)
                .foregroundColor(.red)
                .offset(x: self.direction == .horizontal ? pos.pos : 0.0, y: self.direction == .vertical ? pos.pos : 0.0)
        }
    }
    
    func CGDistanceSquared(from: CGFloat, to: CGFloat) -> CGFloat {
        return pow(from - to, 2)
    }
    
    func minDist(main: CGFloat, numElements: Int, fullSize: CGFloat, initOffset: CGFloat = 0.0, contract: CGFloat = 1.0, debug: Bool = false) -> CGFloat {
        if numElements <= 0 {
            return 0.0
        }
        
        var minDist = CGFloat.infinity
        var minLoc = 0.0
        var iter = 0
        for val in stride(from: -CGFloat(numElements-1), to: CGFloat(numElements), by: 2.0) {
            iter += 1
            let to = ((val * contract) * fullSize)/CGFloat(numElements - 1) + initOffset
            if debug {
                self.markers = []
                self.markers.append(debug_pos(num:iter, pos:to))
            }
            let dist = CGDistanceSquared(from: main, to: to)
            if minDist > dist {
                minDist = dist
                minLoc = to
            }
        }
        return minLoc
    }
}

struct mainView_Previews: PreviewProvider {
    static var previews: some View {
        mainView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext).previewInterfaceOrientation(.portrait)
    }
}

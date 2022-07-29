//
//  ContentView.swift
//  prod-b
//
//  Created by Cameron Bennett on 6/24/22.
//

import SwiftUI
import CoreData
import simd
import Combine
import Swift
import AVFAudio

protocol ContainerView: View {
    associatedtype Content
    init(content: @escaping () -> Content)
}

struct ContentView: View {
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

// MARK: - Start of SongSpace
class SongSquare : ObservableObject, Equatable {
    static func == (lhs: SongSquare, rhs: SongSquare) -> Bool {
        // Need to update for all fields
        return lhs.x == rhs.x && lhs.y == rhs.y && lhs.height == rhs.height && lhs.width == rhs.width && lhs.selected == rhs.selected
    }
    
    @Published var x: CGFloat
    @Published var y: CGFloat
    @Published var height: CGFloat
    @Published var width: CGFloat
    private var selected: Bool
    
    init(x: CGFloat, y: CGFloat) {
        self.x = x
        self.y = y
        self.height = 50
        self.width = 50
        self.selected = false
    }
    
    // MARK: - SongSquare modification methods
    func updatePosition(translation: CGSize, screenSize: CGSize, sensitivity: CGFloat = 1.0) {
        self.x += translation.width * sensitivity
        self.y += translation.height * sensitivity
        
        // Send Signal up to parent view to refresh view with updated Rectangle positions
        self.objectWillChange.send()
    }
    
    func selectSquare() {
        if self.selected {
            self.height = 50
            self.width = 50
        } else {
            self.height = 100
            self.width = 100
        }
        self.selected.toggle()
        
        // Send Signal up to parent view to refresh view with updated Rectangle positions
        self.objectWillChange.send()
    }
    
    // MARK: - SongSquare awareness methods
    // Might exchange for global cursor idea
    func outsideBounds(dim: CGSize) -> Bool {
        return xOutsideBounds(width: dim.width) || yOutsideBounds(height: dim.height)
    }
    
    func xOutsideBounds(width: CGFloat) -> Bool {
        return self.x < 0 || self.x > width
    }
    
    func yOutsideBounds(height: CGFloat) -> Bool {
        return self.y < 0 || self.y > height
    }
    
    func isSelected() -> Bool {
        return self.selected
    }
}

@propertyWrapper
class SpaceWrap : ObservableObject, Equatable {
    static func == (lhs: SpaceWrap, rhs: SpaceWrap) -> Bool {
        return lhs.dict == rhs.dict
    }
    
    @Published private var dict: Dictionary<Int, SongSquare>
    private var c: AnyCancellable?
    
    init(dict: Dictionary<Int, SongSquare>) {
        self.dict = dict
        subscribeToChanges()
    }
    
    // MARK: - Protective Wrapping for storage of squares
    var wrappedValue: Dictionary<Int, SongSquare> {
        get {
            // TODO: Add security checks etc
            return dict
        }
        set {
            // TODO: Add security checks etc
            self.dict = newValue
            subscribeToChanges()
        }
    }
    
    func subscribeToChanges() -> Void {
        c = self.dict.publisher.flatMap({ square in
            square.value.objectWillChange
        }).sink(receiveValue: { [weak self] in
            self?.objectWillChange.send()
        })
    }
}

class SongSpace : ObservableObject {
    // Need to connect to some datastore
    @Published var squares = SpaceWrap(dict: [
        1: SongSquare(x: 50.0, y: 50.0),
        2: SongSquare(x: 150.0, y: 150.0),
        3: SongSquare(x: 250.0, y: 250.0),
        4: SongSquare(x: 350.0, y: 350.0)
    ]) {
        didSet {
            subscribeToChanges()
        }
    }
    
    @Published var buffer = SpaceWrap(dict: [
        5: SongSquare(x: -40.0, y: 300.0),
        6: SongSquare(x: 300.0, y: -100.0),
        7: SongSquare(x: 420.0, y: 300.0),
        8: SongSquare(x: 150.0, y: 420.0)
    ]) {
        didSet {
            subscribeToChanges()
        }
    }
    
    private var c: AnyCancellable?
    
    init() {
        subscribeToChanges()
    }
    
    func subscribeToChanges() -> Void {
        c = self.squares.wrappedValue.publisher.flatMap({ square in
            square.value.objectWillChange
        }).sink(receiveValue: { [weak self] in
            self?.objectWillChange.send()
        })
        c = self.buffer.wrappedValue.publisher.flatMap({ square in
            square.value.objectWillChange
        }).sink(receiveValue: { [weak self] in
            self?.objectWillChange.send()
        })
    }
    
}

struct Square: View {
    @EnvironmentObject var square: SongSquare
    var key: Int
    @Binding var selected: SongSquare?
    
    var body: some View {
        Rectangle()
            .frame(width: square.width, height: square.height, alignment: .center)
            .foregroundColor(.blue)
            .cornerRadius(10.0)
            .offset(x: square.x, y: square.y)
            .animation(.easeInOut, value: square.x)
            .animation(.easeInOut, value: square.y)
            .animation(.easeInOut, value: square.width)
            .animation(.easeInOut, value: square.height)
            .shadow(radius: 5.0)
            .gesture(
                TapGesture()
                    .onEnded({ val in
                        if (selected != nil && selected!.isSelected()) {
                            selected?.selectSquare()
                        }
                        if square != selected && !square.isSelected() {
                            square.selectSquare()
                        }
                        selected = square
                })
            )
    }
}

struct PracticeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>
    
    @StateObject var space = SongSpace()
    @State var geoReadDim: CGSize = CGSize.zero
    @State var prevTrans = CGSize(width: 0, height: 0)
    @State var select: SongSquare?
    var player: AVAudioPlayer = AVAudioPlayer()
    
    var body: some View {
        ZStack {
            GeometryReader { globPos in
                ForEach(Array(space.squares.wrappedValue.keys), id: \.self) { key in
                    withAnimation {
                        Square(key: key, selected: $select)
                            .environmentObject(space.squares.wrappedValue[key]!)
                    }
                }
                .onAppear {
                    self.geoReadDim = globPos.size
                }
            }
            // Planning to separate the GeoReader from this screen
            .frame(width: UIScreen.screenWidth, height: 3*UIScreen.screenHeight/4, alignment: .center)
            .background(Color(.sRGB, white: 0.10, opacity: 0.10))
            .gesture(
                DragGesture()
                    .onChanged({ offsetChange in
                        let change = CGSize(width: offsetChange.translation.width - prevTrans.width, height: offsetChange.translation.height - prevTrans.height)

                        // Update view with new squares
                        self.updateLocal(change: change)
                        self.updateBuffer(change: change)

                        // Keep track of total space change
                        prevTrans = offsetChange.translation
                    })
            )
//            Button {
//                player.url = 
//            } label: {
//                <#code#>
//            }

        }
        .frame(width: UIScreen.screenWidth, height: UIScreen.screenHeight, alignment: .top)
        .background(
            LinearGradient(gradient: Gradient(stops: [Gradient.Stop(color: .orange, location: 0), Gradient.Stop(color: .black, location: 0.2)]), startPoint: .top, endPoint: .bottom)
        )
    }
    
    // Removes blocks that are outside of bounds and replaces them
    func updateLocal(change: CGSize) {
        for (id, value) in space.squares.wrappedValue {
            if value.outsideBounds(dim: self.geoReadDim) {
                self.space.buffer.wrappedValue[id] = self.space.squares.wrappedValue.removeValue(forKey: id)
            } else {
                self.updateSquare(id: id, change: change, store: true)
            }
        }
    }
    
    func updateBuffer(change: CGSize) {
        for (id, value) in space.buffer.wrappedValue {
            if !value.xOutsideBounds(width: self.geoReadDim.width) && !value.yOutsideBounds(height: self.geoReadDim.height) {
                self.space.squares.wrappedValue[id] = self.space.buffer.wrappedValue.removeValue(forKey: id)
                self.updateSquare(id: id, change: change, store: true)
            } else {
                self.updateSquare(id: id, change: change, store: false)
            }
        }
    }
    
    func updateSquare(id: Int, change: CGSize, store: Bool) {
        // Asymptotic dragging
        let dist = change.width * change.width + change.height * change.height
        let factor = 1/(dist/2000 + 1)
        let dragValue = CGSize(width: change.width * factor, height: change.height * factor)
        if store {
            self.space.squares.wrappedValue[id]!.updatePosition(translation: dragValue, screenSize: self.geoReadDim)
        } else {
            self.space.buffer.wrappedValue[id]!.updatePosition(translation: dragValue, screenSize: self.geoReadDim)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        PracticeView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext).previewInterfaceOrientation(.portrait)
    }
}

// MARK: - Start of Extensions
extension UIScreen {
    static let screenHeight = UIScreen.main.bounds.size.height
    static let screenWidth = UIScreen.main.bounds.size.width
    static let screenSize = UIScreen.main.bounds.size
}

extension ContainerView {
    init(@ViewBuilder _ content: @escaping () -> Content) {
        self.init(content: content)
    }
}

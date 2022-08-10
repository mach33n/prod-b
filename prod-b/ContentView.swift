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
import AVFoundation
import Collections

// MARK: - Start of SongSpace
struct Square: View {
    @EnvironmentObject var songSquare: SongSquare
    
    var body: some View {
        ZStack {
            Rectangle().cornerRadius(15.0)
                .frame(width: songSquare.width, height: songSquare.height, alignment: .topLeading)
                .foregroundColor(songSquare.avgColor)
            HStack(spacing: 0) {
                songSquare.image
                    .cornerRadius(5.0)
                    .frame(width: songSquare.isSelected() ? 130 : songSquare.width, height: songSquare.isSelected() ? 130.0 : songSquare.height, alignment: .center)
                    .shadow(radius: 15.0)
                    .zIndex(songSquare.isSelected() ? 1 : 0)
                    .gesture(
                        TapGesture()
                            .onEnded({ [self] val in
                                if songSquare.selected {
                                    AudioPlayer.player.pause()
                                    AudioPlayer.player.replaceCurrentItem(with: nil)
                                    SongSquare.current = nil
                                } else {
                                    if SongSquare.current != nil {
                                        SongSquare.current?.selectSquare()
                                    }
                                    AudioPlayer.player.replaceCurrentItem(with: songSquare.getAVPlayerItem())
                                    MagnitudeChart.loadValues(waveform: songSquare.waveValues)
                                    AudioPlayer.player.play()
                                    SongSquare.current = songSquare
                                }
                                songSquare.selectSquare()
                            }
                        )
                    )
                    .background(Color.black.opacity(0.0001))
                    .padding(Edge.Set.leading, songSquare.isSelected() ? 10.0 : 0.0)
                if songSquare.isSelected() {
                    HStack {
                        VStack {
                            Text("Now Playing").frame(maxWidth: .infinity, alignment: .leading).font(Font(UIFont(name: "Arial-BoldMT", size: 10.0)!)).padding(Edge.Set.bottom, 10.0).padding(Edge.Set.leading, 2.0).foregroundColor(.black)
                            Text("\(songSquare.trackName)").frame(maxWidth: .infinity, alignment: .leading).font(Font(UIFont(name: "Helvetica-Bold", size: 15.0)!)).foregroundColor(.indigo.opacity(0.9))
                            Text("\(songSquare.producerName)").frame(maxWidth: .infinity, alignment: .leading).font(Font(UIFont(name: "GillSans", size: 10.0)!)).padding(Edge.Set.bottom, 20.0).foregroundColor(.black)
                            HStack {
                                Image("desc-arrows").resizable().frame(width: 10, height: 10, alignment: .leading).rotationEffect(.degrees(90))
                                Text("Happy").font(Font(UIFont(name: "GillSans", size: 10.0)!)).frame(alignment: .leading).foregroundColor(.indigo.opacity(0.4)).foregroundColor(.indigo.opacity(0.8))
                                Image("desc-arrows").resizable().frame(width: 10, height: 10, alignment: .leading).rotationEffect(.degrees(270)).foregroundColor(.indigo)
                                Text("Relaxed").font(Font(UIFont(name: "GillSans", size: 10.0)!)).frame(alignment: .leading).foregroundColor(.indigo.opacity(0.8))
                            }.frame(maxWidth: .infinity, alignment: .leading)
                        }.frame(alignment: .leading)
                        VStack {
                            Spacer()
                            Spacer()
                            PlayerButton(frameDim: CGSize(width: 20.0, height: 20.0), imgName: "heart", imgScale: 0.4, selectable: true, darkBack: true)
                            Spacer()
                            PlayerButton(frameDim: CGSize(width: 20.0, height: 20.0), imgName: "add-list", imgScale: 0.4, darkBack: true)
                            Spacer()
                            PlayerButton(frameDim: CGSize(width: 20.0, height: 20.0), imgName: "share", imgScale: 0.4, darkBack: true)
                            Spacer()
                            Spacer()
                        }.frame(width: 15, alignment: .leading).offset(x: -20.0)
                    }.padding(Edge.Set.leading, 10.0)
                }
            }
        }
        .frame(width: songSquare.width, height: songSquare.height, alignment: .center)
        .position(x: songSquare.point.x, y: songSquare.point.y)
        .zIndex(songSquare.isSelected() ? 1 : 0)
        .animation(.easeInOut, value: songSquare.point.x)
        .animation(.easeInOut, value: songSquare.point.y)
        .animation(.easeInOut, value: songSquare.width)
        .animation(.easeInOut, value: songSquare.height)
    }
}

class SongSquare : ObservableObject, Equatable, Hashable {
    static func == (lhs: SongSquare, rhs: SongSquare) -> Bool {
        // Need to update for all fields
        return lhs.point == rhs.point && lhs.selected == rhs.selected
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(key)
    }
    
    static var current: SongSquare?
    static var selOffset: CGPoint = CGPoint.zero
    static var sensitivity: CGFloat = 1.0
    
    var key: String
    @Published var point: CGPoint
    @Published var height: CGFloat
    @Published var width: CGFloat
    @Published var selected: Bool
    var trackName: String
    var producerName: String
    var image: Image
    var audioUrl: String
    var avgColor: Color
    @Published var waveValues: [CGFloat]
    
    init(key: String, x: Double, y: Double, audioURL: String, trackName: String, producerName: String, waveValues: [CGFloat] = [CGFloat](repeating: .zero, count: 50), image: String? = nil) {
        self.key = key
        self.point = CGPoint(x: x, y: y)
        self.height = 50
        self.width = 50
        self.selected = false
        self.trackName = trackName
        self.producerName = producerName
        self.audioUrl = audioURL
        do {
            let url = URL(string: image!)
            let data = try Data(contentsOf: url!)
            let img = UIImage(data: data)
            self.avgColor = img?.averageColor ?? Color(.sRGB, white: 0.1, opacity: 0.9)
            self.image = Image(uiImage: img!).resizable()
        } catch {
            let img = UIImage(named: "sample_art_cover")
            self.avgColor = img?.averageColor ?? Color(.sRGB, white: 0.1, opacity: 0.9)
            self.image = Image("sample_art_cover").resizable()
        }
        self.waveValues = waveValues
    }
    
    // MARK: - SongSquare modification methods
    func updatePosition(translation: CGSize) {
        self.point.x += translation.width * SongSquare.sensitivity
        self.point.y += translation.height * SongSquare.sensitivity
        
        // Send Signal up to parent view to refresh view with updated Rectangle positions
        self.objectWillChange.send()
    }
    
    func selectSquare() {
        if self.selected {
            self.height = 50
            self.width = 50
            self.point = self.point + SongSquare.selOffset
            SongSquare.selOffset = CGPoint.zero
        } else {
            self.height = 150
            self.width = 300
            
            var diff = CGSize.zero
            SongSquare.selOffset = CGPoint.zero
            if self.point.xOutsideBounds(width: PlayerView.geoReadDim.width - 300/2, offset: 300/2) {
                if self.point.x < 300/2 {
                    SongSquare.selOffset.x = self.point.x - 300/2
                } else {
                    SongSquare.selOffset.x = self.point.x - (PlayerView.geoReadDim.width - 300/2)
                }
                diff.width = SongSquare.current!.point.x.clamped(to: 300/2...PlayerView.geoReadDim.width-300/2) - self.point.x
            }
            if self.point.yOutsideBounds(height: PlayerView.geoReadDim.height - 150/2, offset: 150/2) {
                if self.point.y < 300/2 {
                    SongSquare.selOffset.y = self.point.y - 300/2
                } else {
                    SongSquare.selOffset.y = self.point.y - (PlayerView.geoReadDim.height - 300/2)
                }
                diff.height = SongSquare.current!.point.y.clamped(to: 150/2...PlayerView.geoReadDim.height-150/2) - self.point.y
            }
            self.updatePosition(translation: diff)
        }
        self.selected.toggle()
        
        // Send Signal up to parent view to refresh view with updated Rectangle positions
        self.objectWillChange.send()
    }
    
    // MARK: - SongSquare awareness methods
    // Might exchange for global cursor idea
    func outsideBounds(dim: CGSize?, offset: CGSize? = CGSize.zero) -> Bool {
        return self.point.outsideBounds(dim: dim!, offset: offset!)
    }
    
    func xOutsideBounds(width: CGFloat?, offset: CGFloat? = 0.0) -> Bool {
        return self.point.xOutsideBounds(width: width!, offset: offset!)
    }
    
    func yOutsideBounds(height: CGFloat?, offset: CGFloat?) -> Bool {
        return self.point.yOutsideBounds(height: height!, offset: offset!)
    }
    
    func getAVPlayerItem() -> AVPlayerItem {
        return AVPlayerItem(url: NSURL(string: self.audioUrl)! as URL)
    }
    
    func isSelected() -> Bool {
        return self.selected
    }
}

// Useful wrapper for protecting access to the desired dictionaries of squares
@propertyWrapper
class SpaceWrap : ObservableObject, Equatable {
    static func == (lhs: SpaceWrap, rhs: SpaceWrap) -> Bool {
        return lhs.dict == rhs.dict
    }
    
    @Published private var dict: OrderedDictionary<String, SongSquare>
    private var c: AnyCancellable?
    
    init(dict: OrderedDictionary<String, SongSquare>) {
        self.dict = dict
        subscribeToChanges()
    }
    
    // MARK: - Protective Wrapping for storage of squares
    var wrappedValue: OrderedDictionary<String, SongSquare> {
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
    enum axes {
        case Happy_Sad
        case Aggressive_Relaxed
    }
    
    // Need to connect to some datastore
    @Published var squares = SpaceWrap(dict: OrderedDictionary<String, SongSquare>())
    @Published var buffer = SpaceWrap(dict: OrderedDictionary<String, SongSquare>())
    @Published var cursor = CGPoint(x: 0, y: 0)
    private var store = DataStore()
    private var c: AnyCancellable?
    
    init() {
        subscribeToChanges()
        (self.squares, self.buffer) = self.twoDimEvenLoad(axis1: .Happy_Sad, axis2: .Aggressive_Relaxed)
    }
    
    func twoDimEvenLoad(axis1: axes, axis2: axes, numTracks: Int = 1) -> (SpaceWrap, SpaceWrap) {
        return store.pullLocal()
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

struct PlayerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>
    
    @StateObject var space = SongSpace()
    static var geoReadDim: CGSize = CGSize(width: UIScreen.screenWidth, height: 3*UIScreen.screenHeight/4)
    @State var prevTrans = CGSize(width: 0, height: 0)
    @State var selected: SongSquare?
    @State var value: Double = 30
    @State var playing = false
    
    var body: some View {
        let background = Color(red: 0.07, green: 0.07, blue: 0.12)
        ZStack {
            VStack {
                GeometryReader { globPos in
                    RoundedRectangle(cornerRadius: 10.0)
                        .frame(width: 20.0, height: 20.0, alignment: .center)
                        .offset(x: space.cursor.x, y: space.cursor.y)
                        .foregroundStyle(.red)
                    ForEach(space.squares.wrappedValue.values, id: \.self) { square in
                        withAnimation {
                            Square()
                                .frame(width: square.width, height: square.height, alignment: .center)
                                .environmentObject(square)
                        }
                    }
                    .onAppear {
                        PlayerView.geoReadDim = globPos.size
                    }
                }
                .background(Color.black.opacity(0.0001))
                // Planning to separate the GeoReader from this screen
                .frame(width: UIScreen.screenWidth, height: 3*UIScreen.screenHeight/4, alignment: .topLeading)
                .onAppear(perform: {
                    // Update view with new squares
                    self.updateLocal(change: self.space.cursor.toCGSize())
                    self.updateBuffer(change: self.space.cursor.toCGSize())
                    self.updateCursor(change: PlayerView.geoReadDim/2)
                })
                .gesture(
                    DragGesture()
                        .onChanged({ offsetChange in
                            let diff = offsetChange.translation - prevTrans
                            var change = CGSize(width: diff.width, height: diff.height)
                            change = asymDrag(change: change)
                            
                            // Update view with new squares
                            self.updateLocal(change: change)
                            self.updateBuffer(change: change)
                            self.updateCursor(change: change)
                            
                            // Keep track of total space change
                            prevTrans = offsetChange.translation
                        })
                )
                VStack {
                    Spacer(minLength: 10.0)
                    // Waveform and underlying bar
                    HStack {
                        VStack(spacing: 0) {
                            CustomSlider(value: $value, range: (0, 100), knobWidth: 0) { modifiers in
                                ZStack {
                                    LinearGradient(gradient: .init(colors: [Color.pink, Color.purple, Color.blue, Color.blue ]), startPoint: .leading, endPoint: .trailing)
                                    Group {
                                        background // = Color(red: 0.07, green: 0.07, blue: 0.12)
                                        Color.white.opacity(0.2)
                                        LinearGradient(gradient: .init(colors: [Color.gray.opacity(0.1), Color.black.opacity(0.6)]), startPoint: .bottom, endPoint: .top)
                                    }.modifier(modifiers.barRight)
                                }
                                .clipShape(MagnitudeChart.magnitudeChart) // our shape from previous step will mask the bar via clipShape
                            }
                            .frame(width: UIScreen.screenWidth*9/10, height: 60, alignment: .center)
                            .edgesIgnoringSafeArea(.bottom)
                        }
                    }.frame(width: UIScreen.screenWidth)
                    Spacer()
                    
                    // Buttons
                    HStack {
                        Spacer()
                        PlayerButton(frameDim: CGSize(width: 50, height: 50), imgName: "arrow", imgScale: 0.5, rotate: true) {
                            if AudioPlayer.player.currentItem != nil {
                                AudioPlayer.player.changeTime(secs: AudioPlayer.player.currTime - 5.0)
                            }
                        }
                        Spacer()
                        PlayerButton(frameDim: CGSize(width: 90, height: 90), imgName: playing ? "play" : "pause" , imgScale: 2/3) {
                            if AudioPlayer.player.currentItem != nil {
                                if AudioPlayer.player.timeControlStatus == .playing {
                                    AudioPlayer.player.pause()
                                } else {
                                    AudioPlayer.player.play()
                                }
                                playing.toggle()
                            }
                        }
                        Spacer()
                        PlayerButton(frameDim: CGSize(width: 50, height: 50), imgName: "arrow", imgScale: 0.5) {
                            if AudioPlayer.player.currentItem != nil {
                                AudioPlayer.player.changeTime(secs: AudioPlayer.player.currTime + 5.0)
                            }
                        }
                        Spacer()
                        Button {
                            
                        } label: {
                            Image("update-arrows").resizable().scaledToFit().colorInvert()
                        }.frame(width: 20, height: 20, alignment: .center).padding(SwiftUI.Edge.Set.leading, 20.0)
                        
                    }.frame(width: UIScreen.screenWidth*8/10)
                    Spacer()
                }
                .frame(width: UIScreen.screenWidth)
                .background(Color(.sRGB, white: 0.1, opacity: 1.0))
            }
            .frame(width: UIScreen.screenWidth, height: UIScreen.screenHeight, alignment: .center)
        }
        .frame(width: UIScreen.screenWidth, height: UIScreen.screenHeight, alignment: .center)
        .ignoresSafeArea(.all, edges: .top)
        .background(
            ZStack {
                LinearGradient(stops: [.init(color: .blue, location: 0.4), .init(color: .red, location: 0.6)], startPoint: UnitPoint(x: 0.0, y: 0.0), endPoint: UnitPoint(x: 0.0, y: 1.0))
                    .frame(width: UIScreen.screenWidth*2, height: UIScreen.screenHeight*5, alignment: .center)
                    .position(x: UIScreen.screenWidth/2, y: 0.0)
                    .offset(x: 0.0, y: space.cursor.y.clamped(to: -PlayerView.geoReadDim.height/2...UIScreen.screenWidth*5-PlayerView.geoReadDim.height/2))
                LinearGradient(stops: [.init(color: .green, location: 0.4), .init(color: .indigo, location: 0.6)], startPoint: .leading, endPoint: .trailing)
                    .blendMode(BlendMode.exclusion)
                    .frame(width: UIScreen.screenWidth*5, height: UIScreen.screenHeight*2, alignment: .center)
                    .position(x: 0.0, y: UIScreen.screenHeight/2)
                    .offset(x: space.cursor.x.clamped(to: -PlayerView.geoReadDim.width/2...UIScreen.screenWidth*5-PlayerView.geoReadDim.width/2), y: 0.0)
            }.frame(width: UIScreen.screenWidth, height: UIScreen.screenHeight, alignment: .center)
        )
    }
    
    func updateCursor(change: CGSize) {
        self.space.cursor.x += change.width
        self.space.cursor.y += change.height
    }
    
    // Removes blocks that are outside of bounds and replaces them
    func updateLocal(change: CGSize) {
        for (id, value) in space.squares.wrappedValue {
            if value.isSelected() {
                var comb = value.point + SongSquare.selOffset
                var diff = CGSize.zero
                if comb.xOutsideBounds(width: PlayerView.geoReadDim.width - 300/2, offset: 300/2) {
                    SongSquare.selOffset.x += change.width
                    diff.width = SongSquare.current!.point.x.clamped(to: 300/2...PlayerView.geoReadDim.width-300/2) - value.point.x
                } else {
                    diff.width = change.width * SongSquare.sensitivity
                }
                if comb.yOutsideBounds(height: PlayerView.geoReadDim.height - 150/2, offset: 150/2) {
                    SongSquare.selOffset.y += change.height
                    diff.height = SongSquare.current!.point.y.clamped(to: 150/2...PlayerView.geoReadDim.height-150/2) - value.point.y
                } else {
                    diff.height = change.height * SongSquare.sensitivity
                }
                self.updateSquare(id: id, change: diff, store: true)
            } else if value.outsideBounds(dim: PlayerView.geoReadDim) {
                self.space.buffer.wrappedValue[id] = self.space.squares.wrappedValue.removeValue(forKey: id)
            } else {
                self.updateSquare(id: id, change: change, store: true)
            }
        }
    }
    
    func updateBuffer(change: CGSize) {
        for (id, value) in space.buffer.wrappedValue {
            if !value.point.xOutsideBounds(width: PlayerView.geoReadDim.width) && !value.point.yOutsideBounds(height: PlayerView.geoReadDim.height) {
                self.space.squares.wrappedValue[id] = self.space.buffer.wrappedValue.removeValue(forKey: id)
                self.updateSquare(id: id, change: change, store: true)
            } else {
                self.updateSquare(id: id, change: change, store: false)
            }
        }
    }
    
    private func updateSquare(id: String, change: CGSize, store: Bool) {
        if store {
            self.space.squares.wrappedValue[id]!.updatePosition(translation: change)
        } else {
            self.space.buffer.wrappedValue[id]!.updatePosition(translation: change)
        }
    }
    
    private func asymDrag(change: CGSize) -> CGSize {
        // Asymptotic dragging
        let dist = change.width * change.width + change.height * change.height
        let factor = 1/(dist/2000 + 1)
        return CGSize(width: change.width * factor, height: change.height * factor)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        PlayerView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext).previewInterfaceOrientation(.portrait)
    }
}


// MARK: - Start of Extensions
extension UIScreen {
    static let screenHeight = UIScreen.main.bounds.size.height
    static let screenWidth = UIScreen.main.bounds.size.width
    static let screenSize = UIScreen.main.bounds.size
}

extension UIImage {
    var averageColor: Color {
        let ci = CIImage(image: self)!
        let filter = CIFilter(name: "CIAreaAverage", parameters: [
            "inputExtent": CIVector(cgRect: ci.extent),
            "inputImage": ci
        ])!
        let ciimg = filter.outputImage
        
        let context = CIContext()
        let cgimg = context.createCGImage(ciimg!, from: ciimg!.extent)
        let data = CFDataGetBytePtr(cgimg?.dataProvider?.data!)
        return Color(.sRGB, red: Double(data![0])/255.0, green: Double(data![1])/255.0, blue: Double(data![2])/255.0, opacity: Double(data![3])/255.0)
    }
}

extension ContainerView {
    init(@ViewBuilder _ content: @escaping () -> Content) {
        self.init(content: content)
    }
}

extension CGPoint {
    static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        let x = lhs.x + rhs.x
        let y = lhs.y + rhs.y
        return CGPoint(x: x, y: y)
    }
    
    static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        let x = lhs.x - rhs.x
        let y = lhs.y - rhs.y
        return CGPoint(x: x, y: y)
    }
    
    static func * (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        let x = lhs.x * rhs.x
        let y = lhs.y * rhs.y
        return CGPoint(x: x, y: y)
    }
    
    static func == (lhs: CGPoint, rhs: CGPoint) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }
    
    mutating func outsideBounds(dim: CGSize, offset: CGSize = CGSize.zero) -> Bool {
        return self.xOutsideBounds(width: dim.width, offset: offset.width) || self.yOutsideBounds(height: dim.height, offset: offset.height)
    }
    
    mutating func xOutsideBounds(width: CGFloat = UIScreen.screenWidth, offset: CGFloat = 0.0) -> Bool {
        return self.x < offset || self.x > width
    }
    
    mutating func yOutsideBounds(height: CGFloat = UIScreen.screenHeight, offset: CGFloat = 0.0) -> Bool {
        return self.y < offset || self.y > height
    }
    
    mutating func toCGSize() -> CGSize {
        return CGSize(width: self.x, height: self.y)
    }
}

extension CGSize : _VectorMath {
    static func + (lhs: CGSize, rhs: CGSize) -> CGSize {
        let width = lhs.width + rhs.width
        let height = lhs.height + rhs.height
        return CGSize(width: width, height: height)
    }
    
    static func - (lhs: CGSize, rhs: CGSize) -> CGSize {
        let width = lhs.width - rhs.width
        let height = lhs.height - rhs.height
        return CGSize(width: width, height: height)
    }
    
    static func * (lhs: CGSize, rhs: CGSize) -> CGSize {
        let width = lhs.width * rhs.width
        let height = lhs.height * rhs.height
        return CGSize(width: width, height: height)
    }
    
    static func * (lhs: CGSize, rhs: CGFloat) -> CGSize {
        let width = lhs.width * rhs
        let height = lhs.height * rhs
        return CGSize(width: width, height: height)
    }
    
    mutating func toCGPoint() -> CGPoint {
        return CGPoint(x: self.width, y: self.height)
    }
}

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

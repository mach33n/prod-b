//
//  BeatSpace.swift
//  prod-b
//
//  Created by Cameron Bennett on 8/9/22.
//

import SwiftUI
import Collections
import Combine
import Swift
import AVFoundation

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
                                    songSquare.selectSquare()
                                } else {
                                    if SongSquare.current != nil {
                                        SongSquare.current?.selectSquare()
                                    }
                                    AudioPlayer.player.replaceCurrentItem(with: songSquare.getAVPlayerItem()) {
                                        AudioPlayer.player.play()
                                        SongSquare.current = songSquare
                                        songSquare.selectSquare()
                                    }
                                }
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

class SongSpace : ObservableObject {
    enum axes {
        case Happy_Sad
        case Aggressive_Relaxed
    }
    
    // Need to connect to some datastore
    @Published var squares =  OrderedDictionary<String, SongSquare>()
    @Published var buffer = OrderedDictionary<String, SongSquare>()
    private var store = DataStore()
    private var c: AnyCancellable?
    
    init() {
        subscribeToChanges()
        (self.squares, self.buffer) = self.twoDimEvenLoad(axis1: .Happy_Sad, axis2: .Aggressive_Relaxed)
    }
    
    func twoDimEvenLoad(axis1: axes, axis2: axes, numTracks: Int = 1) -> (OrderedDictionary<String, SongSquare>, OrderedDictionary<String, SongSquare>) {
        return store.pullLocal()
    }
    
    func subscribeToChanges() -> Void {
        c = self.squares.publisher.flatMap({ square in
            square.value.objectWillChange
        }).sink(receiveValue: { [weak self] in
            self?.objectWillChange.send()
        })
        c = self.buffer.publisher.flatMap({ square in
            square.value.objectWillChange
        }).sink(receiveValue: { [weak self] in
            self?.objectWillChange.send()
        })
    }
}

struct BeatSpace: View {
    @StateObject private var space = SongSpace()
    @State var prevTrans = CGSize(width: 0, height: 0)
    @State var cursor: CGPoint = CGPoint.zero
    
    var body: some View {
        ZStack {
            GeometryReader { globPos in
                RoundedRectangle(cornerRadius: 10.0)
                    .frame(width: 20.0, height: 20.0, alignment: .center)
                    .offset(x: self.cursor.x, y: self.cursor.y)
                    .foregroundStyle(.red)
                ForEach(space.squares.values, id: \.self) { square in
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
                self.updateLocal(change: self.cursor.toCGSize())
                self.updateBuffer(change: self.cursor.toCGSize())
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
        }.background(
            ZStack {
                LinearGradient(stops: [.init(color: .blue, location: 0.4), .init(color: .red, location: 0.6)], startPoint: UnitPoint(x: 0.0, y: 0.0), endPoint: UnitPoint(x: 0.0, y: 1.0))
                    .frame(width: UIScreen.screenWidth*2, height: UIScreen.screenHeight*5, alignment: .center)
                    .position(x: UIScreen.screenWidth/2, y: 0.0)
                    .offset(x: 0.0, y: self.cursor.y.clamped(to: -PlayerView.geoReadDim.height/2...UIScreen.screenWidth*5-PlayerView.geoReadDim.height/2))
                LinearGradient(stops: [.init(color: .green, location: 0.4), .init(color: .indigo, location: 0.6)], startPoint: .leading, endPoint: .trailing)
                    .blendMode(BlendMode.exclusion)
                    .frame(width: UIScreen.screenWidth*5, height: UIScreen.screenHeight*2, alignment: .center)
                    .position(x: 0.0, y: UIScreen.screenHeight/2)
                    .offset(x: self.cursor.x.clamped(to: -PlayerView.geoReadDim.width/2...UIScreen.screenWidth*5-PlayerView.geoReadDim.width/2), y: 0.0)
            }.frame(width: UIScreen.screenWidth, height: UIScreen.screenHeight, alignment: .center)
        )
    }
    
    func updateCursor(change: CGSize) {
        self.cursor.x += change.width
        self.cursor.y += change.height
    }
    
    // Removes blocks that are outside of bounds and replaces them
    func updateLocal(change: CGSize) {
        for (id, value) in space.squares {
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
                self.space.buffer[id] = self.space.squares.removeValue(forKey: id)
            } else {
                self.updateSquare(id: id, change: change, store: true)
            }
        }
    }
    
    func updateBuffer(change: CGSize) {
        for (id, value) in space.buffer {
            if !value.point.xOutsideBounds(width: PlayerView.geoReadDim.width) && !value.point.yOutsideBounds(height: PlayerView.geoReadDim.height) {
                self.space.squares[id] = self.space.buffer.removeValue(forKey: id)
                self.updateSquare(id: id, change: change, store: true)
            } else {
                self.updateSquare(id: id, change: change, store: false)
            }
        }
    }
    
    private func updateSquare(id: String, change: CGSize, store: Bool) {
        if store {
            self.space.squares[id]!.updatePosition(translation: change)
        } else {
            self.space.buffer[id]!.updatePosition(translation: change)
        }
    }
    
    private func asymDrag(change: CGSize) -> CGSize {
        // Asymptotic dragging
        let dist = change.width * change.width + change.height * change.height
        let factor = 1/(dist/2000 + 1)
        return CGSize(width: change.width * factor, height: change.height * factor)
    }
}


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
    
    @Binding var purchasing: Bool
    
    var body: some View {
        ZStack {
            Rectangle().cornerRadius(15.0)
                .frame(width: songSquare.size.width, height: songSquare.size.height, alignment: .topLeading)
                .foregroundColor(songSquare.avgColor)
            HStack(spacing: 0) {
                songSquare.image
                    .cornerRadius(5.0)
                    .frame(width: songSquare.isSelected() ? 130 : songSquare.size.width, height: songSquare.isSelected() ? 130.0 : songSquare.size.height, alignment: .center)
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
//                                    AudioPlayer.player.replaceCurrentItem(with: songSquare.getAVPlayerItem())
                                    AudioPlayer.player.play()
                                    SongSquare.current = songSquare
                                    songSquare.selectSquare()
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
        .frame(width: songSquare.size.width, height: songSquare.size.height, alignment: .center)
        .position(x: songSquare.point.x, y: songSquare.point.y)
        .zIndex(songSquare.isSelected() ? 1 : 0)
        .animation(.easeInOut, value: songSquare.point.x)
        .animation(.easeInOut, value: songSquare.point.y)
        .animation(.easeInOut, value: songSquare.size.width)
        .animation(.easeInOut, value: songSquare.size.height)
        .onLongPressGesture {
            self.purchasing.toggle()
        }
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
    var selOffset: CGPoint = CGPoint.zero
    
    var key: String
    @Published var point: CGPoint
    @Published var size: CGSize
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
        self.size = CGSize(width: 50, height: 50)
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
    
    init(res: SquareRes) {
        self.key = res._id
        self.point = CGPoint(x: res.happyScore, y: res.aggScore)
        self.size = CGSize(width: 50, height: 50)
        self.selected = false
        self.trackName = res.trackName
        self.producerName = res.producerName
        self.audioUrl = res.audioUrl.absoluteString
        do {
            let url = URL(string: res.imageUrl.absoluteString)
            let data = try Data(contentsOf: url!)
            let img = UIImage(data: data)
            self.avgColor = img?.averageColor ?? Color(.sRGB, white: 0.1, opacity: 0.9)
            self.image = Image(uiImage: img!).resizable()
        } catch {
            let img = UIImage(named: "sample_art_cover")
            self.avgColor = img?.averageColor ?? Color(.sRGB, white: 0.1, opacity: 0.9)
            self.image = Image("sample_art_cover").resizable()
        }
        self.waveValues = res.waveform
    }
    
    // MARK: - SongSquare modification methods
    func updatePosition(translation: CGSize) {
        self.point.x += translation.width
        self.point.y += translation.height
        
        // Send Signal up to parent view to refresh view with updated Rectangle positions
        self.objectWillChange.send()
    }
    
    func selectSquare() {
        if self.selected {
            self.size = CGSize(width: 50.0, height: 50.0)
            self.point = self.point + self.selOffset
        } else {
            self.size = CGSize(width: 300.0, height: 150.0)
            
            var diff = CGSize.zero
            self.selOffset = CGPoint.zero
            if self.point.xOutsideBounds(width: PlayerView.geoReadDim.width - 300/2, offset: 300/2) {
                if self.point.x < 300/2 {
                    self.selOffset.x = self.point.x - 300/2
                } else {
                    self.selOffset.x = self.point.x - (PlayerView.geoReadDim.width - 300/2)
                }
                diff.width = SongSquare.current!.point.x.clamped(to: 300/2...PlayerView.geoReadDim.width-300/2) - self.point.x
            }
            if self.point.yOutsideBounds(height: PlayerView.geoReadDim.height - 150/2, offset: 150/2) {
                if self.point.y < 300/2 {
                    self.selOffset.y = self.point.y - 300/2
                } else {
                    self.selOffset.y = self.point.y - (PlayerView.geoReadDim.height - 300/2)
                }
                diff.height = SongSquare.current!.point.y.clamped(to: 150/2...PlayerView.geoReadDim.height-150/2) - self.point.y
            }
            self.updatePosition(translation: diff)
        }
        self.selected.toggle()
        self.selOffset = CGPoint.zero
        
        // Send Signal up to parent view to refresh view with updated Rectangle positions
        self.objectWillChange.send()
    }
    
    func updateSel(change: CGSize) -> CGSize {
        var comb = self.point + self.selOffset
        var diff = CGSize.zero
        if comb.xOutsideBounds(width: PlayerView.geoReadDim.width - 300/2, offset: 300/2) {
            self.selOffset.x += change.width
            diff.width = SongSquare.current!.point.x.clamped(to: 300/2...PlayerView.geoReadDim.width-300/2) - self.point.x
        } else {
            diff.width = change.width
        }
        if comb.yOutsideBounds(height: PlayerView.geoReadDim.height - 150/2, offset: 150/2) {
            self.selOffset.y += change.height
            diff.height = SongSquare.current!.point.y.clamped(to: 150/2...PlayerView.geoReadDim.height-150/2) - self.point.y
        } else {
            diff.height = change.height
        }
        return diff
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
        NotificationCenter.default.addObserver(self.buffer, selector: #selector(updateSquares), name: NSNotification.Name ("com.user.login.success"), object: nil)
        self.pullSquares()
        self.update(change: BeatSpace.cursor.toCGSize())
    }
    
    @objc func updateSquares() {
        print("Update")
    }
    
    
    func pullSquares() {
        let body: SquareReq = SquareReq(axis1: "happy", axis2: "aggressive", limit: 5)
        
        var thing = Endpoints.retrieve(body)
        let url = thing.process()
        
        let task = URLSession.shared.dataTask(with: url!) { data, res, err in
            DispatchQueue.main.sync {
                guard let data = data else { return }
                do {
                    let output = try JSONDecoder().decode([SquareRes].self, from: data)
                    print(output)
                    print(res)
                    print()
                    print(err)
                    for entry in output {
                        self.buffer[entry._id] = SongSquare(res: entry)
                    }
                } catch {
                    print("Weird")
                    print(error)
                    return
                }
            }
        }
        task.resume()
    }

    func update(change: CGSize) {
        self.updateLocal(change: change)
        self.updateBuffer(change: change)
    }
    
    func update(changelocal: CGSize, changebuffer: CGSize) {
        self.updateLocal(change: changelocal)
        self.updateBuffer(change: changebuffer)
    }
    private func updateLocal(change: CGSize) {
        for (id, value) in squares {
            if value.isSelected() {
                let diff = value.updateSel(change: change)
                self.updateSquare(id: id, change: diff, store: true)
            } else if value.outsideBounds(dim: PlayerView.geoReadDim) {
                self.buffer[id] = self.squares.removeValue(forKey: id)
            } else {
                self.updateSquare(id: id, change: change, store: true)
            }
        }
    }
    
    private func updateBuffer(change: CGSize) {
        for (id, value) in buffer {
            if !value.point.xOutsideBounds(width: PlayerView.geoReadDim.width) && !value.point.yOutsideBounds(height: PlayerView.geoReadDim.height) {
                self.squares[id] = self.buffer.removeValue(forKey: id)
                self.updateSquare(id: id, change: change, store: true)
            } else {
                self.updateSquare(id: id, change: change, store: false)
            }
        }
    }
    
    private func updateSquare(id: String, change: CGSize, store: Bool) {
        if store {
            squares[id]!.updatePosition(translation: change)
        } else {
            buffer[id]!.updatePosition(translation: change)
        }
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
    @State private var space: SongSpace = SongSpace()
    @State private var prevTrans = CGSize(width: 0, height: 0)
    @State static var cursor: CGPoint = CGPoint.zero
    @State var purchasing: Bool = false
    
    var body: some View {
        ZStack {
            GeometryReader { globPos in
                RoundedRectangle(cornerRadius: 10.0)
                    .frame(width: 20.0, height: 20.0, alignment: .center)
                    .offset(x: BeatSpace.cursor.x, y: BeatSpace.cursor.y)
                    .foregroundStyle(.red)
                ForEach(space.squares.values, id: \.self) { square in
                    withAnimation {
                        Square(purchasing: $purchasing)
                            .frame(width: square.size.width, height: square.size.height, alignment: .center)
                            .environmentObject(square)
                    }
                }
            }
            .background(self.purchasing ? Color.black.opacity(0.5) : Color.black.opacity(0.0001))
            // Planning to separate the GeoReader from this screen
            .frame(width: UIScreen.screenWidth, height: 3*UIScreen.screenHeight/4, alignment: .topLeading)
            .onAppear(perform: {
                // Update view with new squares
                space.update(changelocal: BeatSpace.cursor.toCGSize(), changebuffer: BeatSpace.cursor.toCGSize())
                BeatSpace.cursor = CGPoint(x: PlayerView.geoReadDim.width/2, y: PlayerView.geoReadDim.height/2)
            })
            .gesture(
                DragGesture()
                    .onChanged({ offsetChange in
                        let diff = offsetChange.translation - prevTrans
                        var change = CGSize(width: diff.width, height: diff.height)
                        change = asymDrag(change: change)
                        
                        // Update view with new squares
                        space.update(change: change)
                        
                        //Update cursor for ref
                        BeatSpace.cursor = BeatSpace.cursor + change.toCGPoint()
                        
                        // Keep track of total space change
                        prevTrans = offsetChange.translation
                    })
            )
            .onTapGesture {
                if self.purchasing {
                    self.purchasing = false
                }
            }
            if self.purchasing {
                withAnimation(.easeIn) {
                    PurchaseView()
                }
            }
        }.background(
            ZStack {
                LinearGradient(stops: [.init(color: .blue, location: 0.4), .init(color: .red, location: 0.6)], startPoint: UnitPoint(x: 0.0, y: 0.0), endPoint: UnitPoint(x: 0.0, y: 1.0))
                    .frame(width: UIScreen.screenWidth*2, height: UIScreen.screenHeight*5, alignment: .center)
                    .position(x: UIScreen.screenWidth/2, y: 0.0)
                    .offset(x: 0.0, y: BeatSpace.cursor.y.clamped(to: -PlayerView.geoReadDim.height/2...UIScreen.screenWidth*5-PlayerView.geoReadDim.height/2))
                LinearGradient(stops: [.init(color: .green, location: 0.4), .init(color: .indigo, location: 0.6)], startPoint: .leading, endPoint: .trailing)
                    .blendMode(BlendMode.exclusion)
                    .frame(width: UIScreen.screenWidth*5, height: UIScreen.screenHeight*2, alignment: .center)
                    .position(x: 0.0, y: UIScreen.screenHeight/2)
                    .offset(x: BeatSpace.cursor.x.clamped(to: -PlayerView.geoReadDim.width/2...UIScreen.screenWidth*5-PlayerView.geoReadDim.width/2), y: 0.0)
            }.frame(width: UIScreen.screenWidth, height: UIScreen.screenHeight, alignment: .center)
        )
    }
    
    private func asymDrag(change: CGSize) -> CGSize {
        // Asymptotic dragging
        let dist = change.width * change.width + change.height * change.height
        let factor = 1/(dist/2000 + 1)
        return CGSize(width: change.width * factor, height: change.height * factor)
    }
}


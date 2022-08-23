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

struct PlayerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>
    
    
    static var geoReadDim: CGSize = CGSize(width: UIScreen.screenWidth, height: 3*UIScreen.screenHeight/4)
    
    @State var value: Double = 30
    @State var playing = false
    @State var space = BeatSpace()
    @State var looping = false
    
    var bottomBar: some View {
        HStack {
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
                if self.looping {
                    self.looping = AudioPlayer.player.remLoop()
                } else {
                    self.looping = AudioPlayer.player.initLoop()
                }
            } label: {
                Image("update-arrows").resizable().scaledToFit().colorInvert().colorMultiply(self.looping ? .green : .white)
            }.frame(width: 20, height: 20, alignment: .center).padding(SwiftUI.Edge.Set.leading, 20.0)
            
        }.frame(width: UIScreen.screenWidth*8/10)
    }
    
    var body: some View {
        let background = Color(red: 0.07, green: 0.07, blue: 0.12)
        ZStack {
            VStack {
                space
                VStack {
                    Spacer(minLength: 10.0)
                    // Waveform and underlying bar
                    HStack {
                        VStack(spacing: 0) {
                            PlayerSlider(value: $value, range: (0, 100), knobWidth: 0) { modifiers in
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
                    bottomBar
                    Spacer()
                }
                .frame(width: UIScreen.screenWidth)
                .background(Color(.sRGB, white: 0.1, opacity: 1.0))
            }
            .frame(width: UIScreen.screenWidth, height: UIScreen.screenHeight, alignment: .center)
        }
        .frame(width: UIScreen.screenWidth, height: UIScreen.screenHeight, alignment: .center)
    }
    
    func updatePurchase() {
        self.space.purchasing.toggle()
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

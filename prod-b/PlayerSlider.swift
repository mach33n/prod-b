//
//  PlayerSlider.swift
//  prod-b
//
//  Created by Cameron Bennett on 7/31/22.
//
//  Recieved assistance from this article: https://betterprogramming.pub/reusable-components-in-swiftui-custom-sliders-8c115914b856
//  Need to revisit at some point

import Foundation
import SwiftUI
import AVFoundation
import Combine
import Accelerate

final class AudioPlayer: AVPlayer, ObservableObject {
    @Published var currTime: Double = 0.0
    static var player: AudioPlayer = AudioPlayer()
    static var waveParser: AVAudioPlayer? = nil
    private var token: Any?
    
    var currTimePassed: AnyPublisher<Double, Never> {
        $currTime
            .eraseToAnyPublisher()
    }
    
    override init() {
        super.init()
        initObserver()
    }
    
    func initObserver() {
        self.token = self.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), queue: DispatchQueue.main) { [weak self] _ in
            if self?.timeControlStatus == .playing {
                self?.currTime = self?.currentTime().seconds ?? 0.0
            }
        }
    }
    
    func changeTime(secs: Double) {
        let timeCM = CMTime(seconds: secs, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        self.seek(to: timeCM)
    }
    
    deinit {
        if self.token != nil {
            self.removeTimeObserver(self.token!)
        }
        self.token = nil
    }
}

struct CustomSliderComponents {
    let barLeft: CustomSliderModifier
    let barRight: CustomSliderModifier
    let knob: CustomSliderModifier
}

struct CustomSliderModifier: ViewModifier {
    enum Name {
        case barLeft
        case barRight
        case knob
    }
    let name: Name
    let size: CGSize
    let offset: CGFloat
    
    func body(content: Content) -> some View {
        content.frame(width: size.width).position(x: size.width*0.5, y: size.height*0.5).offset(x: offset)
    }
}

struct CustomSlider<Component: View>: View {

    @Binding var value: Double
    var range: (Double, Double)
    var knobWidth: CGFloat?
    let viewBuilder: (CustomSliderComponents) -> Component
    
    
    init(value: Binding<Double>, range: (Double, Double), knobWidth: CGFloat? = nil, _ viewBuilder: @escaping (CustomSliderComponents) -> Component) {
        _value = value
        self.range = range
        self.viewBuilder = viewBuilder
        self.knobWidth = knobWidth
    }
    
    var body: some View {
        return GeometryReader { geometry in
            self.view(geometry: geometry)
        }
    }
    
    private func view(geometry: GeometryProxy) -> some View {
        let frame = geometry.frame(in: .global)
        let offsetX = self.getOffsetX(frame: frame)
        let knobSize = CGSize(width: knobWidth ?? frame.height, height: frame.height)
        let barLeftSize = CGSize(width: CGFloat(offsetX + knobSize.width * 0.5), height:  frame.height)
        let barRightSize = CGSize(width: frame.width - barLeftSize.width, height: frame.height)
        
        let modifiers = CustomSliderComponents(
                    barLeft: CustomSliderModifier(name: .barLeft, size: barLeftSize, offset: 0),
                    barRight: CustomSliderModifier(name: .barRight, size: barRightSize, offset: barLeftSize.width),
                    knob: CustomSliderModifier(name: .knob, size: knobSize, offset: offsetX)
        )
        return ZStack {
            viewBuilder(modifiers)
            .onReceive(AudioPlayer.player.currTimePassed) { newVal in
                if AudioPlayer.player.currentItem != nil && AudioPlayer.player.timeControlStatus == .playing {
                    let width = (knob: Double(knobWidth ?? frame.size.height), view: Double(frame.size.width))
                    let xrange = (min: Double(0), max: AudioPlayer.player.currentItem!.duration.seconds)
                    var value = newVal
                    value -= 0.5*width.knob
                    value = value > xrange.max ? xrange.max : value
                    value = value < xrange.min ? xrange.min : value
                    value = value.convert(fromRange: (xrange.min, xrange.max), toRange: range)
                    self.value = value
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                .onChanged({ drag in
                    AudioPlayer.player.pause()
                    let width = (knob: Double(knobWidth ?? frame.size.height), view: Double(frame.size.width))
                    let xrange = (min: Double(0), max: Double(width.view - width.knob))
                    var value = Double(drag.startLocation.x + drag.translation.width)
                    value -= 0.5*width.knob
                    value = value > xrange.max ? xrange.max : value
                    value = value < xrange.min ? xrange.min : value
                    if AudioPlayer.player.currentItem != nil {
                        let trange = (min: Double(0), max: AudioPlayer.player.currentItem!.duration.seconds)
                        value = value.convert(fromRange: (xrange.min, xrange.max), toRange: (trange.min, trange.max))
                        value = value.convert(fromRange: (trange.min, trange.max), toRange: range)
                    } else {
                        value = value.convert(fromRange: (xrange.min, xrange.max), toRange: range)
                    }
                    self.value = value
                })
                .onEnded({ drag in
                    self.value = value
                    if AudioPlayer.player.currentItem != nil {
                        let trange = (min: Double(0), max: AudioPlayer.player.currentItem!.duration.seconds)
                        let thing = self.value.convert(fromRange: range, toRange: (trange.min, trange.max))
                        AudioPlayer.player.changeTime(secs: thing)
                        AudioPlayer.player.play()
                    }
                })
            )
        }
    }
    
    private func getOffsetX(frame: CGRect) -> CGFloat {
        let width = (knob: knobWidth ?? frame.size.height, view: frame.size.width)
        let xrange: (Double, Double) = (0, Double(width.view - width.knob))
        let result = self.value.convert(fromRange: range, toRange: xrange)
        return CGFloat(result)
    }
}

struct MagnitudeChart: Shape {
    static var numSamples: Int = 50
    static var values: [CGFloat] = (1...50).map{_ in CGFloat(arc4random())}
    static var magnitudeChart: MagnitudeChart = MagnitudeChart()
    
    static func loadValues(waveform: [CGFloat]) {
//        MagnitudeChart.values = waveform
    }
    
    static func genValues(audioUrl: String) -> Future<[CGFloat], CancellationError> {
        return Future() { promise in
            var ind = 0
            var values = [CGFloat](repeating: .zero, count: numSamples)
            do {
                let parser = try AVAudioPlayer(data: Data(contentsOf: NSURL(string: audioUrl)! as URL))
                parser.isMeteringEnabled = true
                parser.prepareToPlay()
                parser.play()
                parser.volume = 0.0
                parser.rate = .infinity
//                print("interval:\(parser.duration/Double(MagnitudeChart.numSamples))")
                let timer = Timer.scheduledTimer(withTimeInterval: (parser.duration / .infinity)/Double(MagnitudeChart.numSamples), repeats: true) { timer in
//                    print("AHHHHHHHHHHH")
                    if ind >= MagnitudeChart.numSamples {
                        print("Done")
                        promise(Result.success(values))
                        timer.invalidate()
                        return
                    }
                    parser.updateMeters()
                    let avgPows = (0...parser.numberOfChannels).map { num in
                        CGFloat(parser.averagePower(forChannel: Int(num)))
                    }
//                    print(CGFloat(parser.averagePower(forChannel: Int(0))))
                    values[ind] = avgPows.reduce(0, +) / CGFloat(parser.numberOfChannels)
                    ind += 1
                }
                RunLoop.current.add(timer, forMode: .common)
            } catch {
                promise(Result.failure(CancellationError()))
            }
        }
    }

    // Don't fully understand but will come back to
    func path(in rect: CGRect) -> Path {
        let maxValue = MagnitudeChart.values.max() ?? 9
        let minValue = MagnitudeChart.values.min() ?? 0
        var path = Path()
        path.move(to: rect.origin)
        for (index,value) in MagnitudeChart.values.enumerated() {
            let padding = rect.height*(1-value/(maxValue - minValue))
            let barWidth: CGFloat = 2
            let spacing = (rect.width - barWidth*CGFloat(MagnitudeChart.values.count))/CGFloat(MagnitudeChart.values.count - 1)
            let barRect = CGRect(x: (CGFloat(barWidth)+spacing)*CGFloat(index),
                                 y: rect.origin.y + padding*0.5 + rect.origin.y,
                                 width: barWidth,
                                 height: rect.height - padding)
            path.addRoundedRect(in: barRect, cornerSize: CGSize(width:1, height: 1))
        }
        let bounds = path.boundingRect
        let scaleX = rect.size.width/bounds.size.width
        let scaleY = rect.size.height/bounds.size.height
        return path.applying(CGAffineTransform(scaleX: scaleX, y: scaleY))
    }
}

extension Double {
    func convert(fromRange: (Double, Double), toRange: (Double, Double)) -> Double {
        // Example: if self = 1, fromRange = (0,2), toRange = (10,12) -> solution = 11
        var value = self
        value -= fromRange.0
        value /= Double(fromRange.1 - fromRange.0)
        value *= toRange.1 - toRange.0
        value += toRange.0
        return value
    }
}

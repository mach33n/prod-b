//
//  AudioPlayer.swift
//  prod-b
//
//  Created by Cameron Bennett on 8/9/22.
//

import Foundation
import AVFoundation
import Combine

final class AudioPlayer: AVPlayer, ObservableObject {
    @Published var currTime: Double = 0.0
    static var player: AudioPlayer = AudioPlayer()
    private var loopObserver: NSObjectProtocol? = nil
    private var token: Any?
    private var queue: DispatchQueue = DispatchQueue(label: "trackQueue")
    
    var currTimePassed: AnyPublisher<Double, Never> {
        $currTime
            .eraseToAnyPublisher()
    }
    
    override init() {
        super.init()
        initObserver()
    }
    
    func initLoop() -> Bool {
        self.loopObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: AudioPlayer.player.currentItem, queue: .main) { _ in
            AudioPlayer.player.seek(to: CMTime.zero)
            AudioPlayer.player.play()
        }
        return self.loopObserver != nil
    }
    
    func remLoop() -> Bool {
        NotificationCenter.default.removeObserver(self.loopObserver)
        return false
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
        AudioPlayer.player.remLoop()
    }
}

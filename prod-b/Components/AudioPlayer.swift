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
    static var waveParser: AVAudioPlayer? = nil
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
    
    func initObserver() {
        self.token = self.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), queue: DispatchQueue.main) { [weak self] _ in
            if self?.timeControlStatus == .playing {
                self?.currTime = self?.currentTime().seconds ?? 0.0
            }
        }
    }
    
    func replaceCurrentItem(with item: AVPlayerItem?, handler: () -> ()) {
        queue.sync {
            super.replaceCurrentItem(with: item)
            let outputSettingsDict: [String : Any] = [
                    AVFormatIDKey: Int(kAudioFormatLinearPCM),
                    AVLinearPCMBitDepthKey: 16,
                    AVLinearPCMIsBigEndianKey: false,
                    AVLinearPCMIsFloatKey: false,
                    AVLinearPCMIsNonInterleaved: false
                ]
                
            let readerOutput = AVAssetReaderTrackOutput(track: item!.asset.tracks[0],
                                                            outputSettings: outputSettingsDict)
            handler()
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

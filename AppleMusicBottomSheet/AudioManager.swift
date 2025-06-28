//
//  AudioManager.swift
//  AppleMusicBottomSheet
//
//  Created by Claude on 28/06/25.
//

import Foundation
import AVFoundation
import MediaPlayer
import SwiftUI

class AudioManager: NSObject, ObservableObject {
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var currentTrackIndex = 0
    @Published var currentTrack: AudioTrack?
    @Published var playlist: [AudioTrack] = []
    @Published var volume: Float = 0.5
    
    private var player: AVAudioPlayer?
    private var timer: Timer?
    
    override init() {
        super.init()
        setupAudioSession()
        setupRemoteTransportControls()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    private func setupRemoteTransportControls() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.play()
            return .success
        }
        
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }
        
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.nextTrack()
            return .success
        }
        
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.previousTrack()
            return .success
        }
    }
    
    func loadTrack(_ track: AudioTrack) {
        guard let url = track.url else { return }
        
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            player?.prepareToPlay()
            player?.volume = volume
            
            currentTrack = track
            duration = player?.duration ?? 0
            currentTime = 0
            
            updateNowPlayingInfo()
        } catch {
            print("Error loading track: \(error)")
        }
    }
    
    func play() {
        player?.play()
        isPlaying = true
        startTimer()
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
        stopTimer()
    }
    
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    func seek(to time: TimeInterval) {
        player?.currentTime = time
        currentTime = time
    }
    
    func nextTrack() {
        guard !playlist.isEmpty else { return }
        currentTrackIndex = (currentTrackIndex + 1) % playlist.count
        loadTrack(playlist[currentTrackIndex])
        if isPlaying {
            play()
        }
    }
    
    func previousTrack() {
        guard !playlist.isEmpty else { return }
        currentTrackIndex = currentTrackIndex > 0 ? currentTrackIndex - 1 : playlist.count - 1
        loadTrack(playlist[currentTrackIndex])
        if isPlaying {
            play()
        }
    }
    
    func setVolume(_ newVolume: Float) {
        volume = newVolume
        player?.volume = newVolume
    }
    
    func addToPlaylist(_ tracks: [AudioTrack]) {
        playlist.append(contentsOf: tracks)
        if currentTrack == nil && !playlist.isEmpty {
            currentTrackIndex = 0
            loadTrack(playlist[0])
        }
    }
    
    func setPlaylist(_ tracks: [AudioTrack], startIndex: Int = 0) {
        playlist = tracks
        if !playlist.isEmpty && startIndex < playlist.count {
            currentTrackIndex = startIndex
            loadTrack(playlist[startIndex])
        } else if playlist.isEmpty {
            // 如果播放列表为空，清空当前播放状态
            clearCurrentTrack()
        }
    }
    
    func clearCurrentTrack() {
        player?.stop()
        player = nil
        currentTrack = nil
        currentTime = 0
        duration = 0
        isPlaying = false
        stopTimer()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.player else { return }
            self.currentTime = player.currentTime
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateNowPlayingInfo() {
        guard let track = currentTrack else { return }
        
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = track.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = track.artist
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        
        if let artwork = track.artwork {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: artwork.size) { _ in
                return artwork
            }
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
}

extension AudioManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            nextTrack()
        }
    }
}

struct AudioTrack: Identifiable {
    let id = UUID()
    let title: String
    let artist: String
    let url: URL?
    let artwork: UIImage?
    let duration: TimeInterval
    
    init(title: String, artist: String, url: URL?, artwork: UIImage? = nil, duration: TimeInterval = 0) {
        self.title = title
        self.artist = artist
        self.url = url
        self.artwork = artwork
        self.duration = duration
    }
}
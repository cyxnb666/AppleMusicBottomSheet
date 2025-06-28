//
//  MusicImporter.swift
//  AppleMusicBottomSheet
//
//  Created by Claude on 28/06/25.
//

import SwiftUI
import UniformTypeIdentifiers
import AVFoundation

class MusicLibrary: ObservableObject {
    @Published var tracks: [AudioTrack] = []
    private let userDefaults = UserDefaults.standard
    private let tracksKey = "SavedTracks"
    private let versionKey = "SavedTracksVersion"
    private let currentVersion = 2 // 增加版本号来处理数据格式升级
    
    init() {
        checkDataVersion()
        loadSavedTracks()
    }
    
    private func checkDataVersion() {
        let savedVersion = userDefaults.integer(forKey: versionKey)
        if savedVersion < currentVersion {
            // 清除旧数据，因为格式已经改变
            userDefaults.removeObject(forKey: tracksKey)
            userDefaults.set(currentVersion, forKey: versionKey)
        }
    }
    
    func addTracks(_ newTracks: [AudioTrack]) {
        tracks.append(contentsOf: newTracks)
        saveTracks()
    }
    
    func deleteTrack(at index: Int) {
        guard index >= 0 && index < tracks.count else { return }
        
        let trackToDelete = tracks[index]
        
        // 删除文件系统中的音频文件
        if let url = trackToDelete.url {
            try? FileManager.default.removeItem(at: url)
        }
        
        // 从数组中删除
        tracks.remove(at: index)
        
        // 保存更新后的列表
        saveTracks()
    }
    
    func deleteTrack(_ track: AudioTrack) {
        if let index = tracks.firstIndex(where: { $0.id == track.id }) {
            deleteTrack(at: index)
        }
    }
    
    func deleteTracks(at indexSet: IndexSet) {
        // 从后往前删除，避免索引变化问题
        let sortedIndices = indexSet.sorted(by: >)
        
        for index in sortedIndices {
            deleteTrack(at: index)
        }
    }
    
    private func saveTracks() {
        let trackData = tracks.compactMap { track in
            var data: [String: Any] = [
                "title": track.title,
                "artist": track.artist,
                "urlPath": track.url?.lastPathComponent ?? "",
                "duration": track.duration
            ]
            
            // 保存图片数据
            if let artwork = track.artwork,
               let imageData = artwork.jpegData(compressionQuality: 0.8) {
                data["artworkData"] = imageData
            }
            
            return data
        }
        userDefaults.set(trackData, forKey: tracksKey)
    }
    
    private func loadSavedTracks() {
        guard let trackData = userDefaults.array(forKey: tracksKey) as? [[String: Any]] else { return }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        tracks = trackData.compactMap { data in
            guard let title = data["title"] as? String,
                  let artist = data["artist"] as? String,
                  let urlPath = data["urlPath"] as? String else { return nil }
            
            let fileURL = documentsPath.appendingPathComponent(urlPath)
            guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
            
            let duration = data["duration"] as? TimeInterval ?? 0
            
            // 加载图片数据
            var artwork: UIImage?
            if let artworkData = data["artworkData"] as? Data {
                artwork = UIImage(data: artworkData)
            }
            
            return AudioTrack(title: title, artist: artist, url: fileURL, artwork: artwork, duration: duration)
        }
    }
}

struct DocumentPickerView: UIViewControllerRepresentable {
    @ObservedObject var musicLibrary: MusicLibrary
    @ObservedObject var audioManager: AudioManager
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [
            UTType.mp3,
            UTType.mpeg4Audio,
            UTType.audio
        ], asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPickerView
        
        init(_ parent: DocumentPickerView) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            Task {
                await processAudioFiles(urls)
            }
        }
        
        @MainActor
        private func processAudioFiles(_ urls: [URL]) async {
            var newTracks: [AudioTrack] = []
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            
            for url in urls {
                do {
                    let fileName = url.lastPathComponent
                    let destinationURL = documentsPath.appendingPathComponent(fileName)
                    
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        try FileManager.default.removeItem(at: destinationURL)
                    }
                    
                    try FileManager.default.copyItem(at: url, to: destinationURL)
                    
                    let track = await extractTrackInfo(from: destinationURL)
                    newTracks.append(track)
                } catch {
                    print("Error processing file \(url.lastPathComponent): \(error)")
                }
            }
            
            parent.musicLibrary.addTracks(newTracks)
            parent.audioManager.addToPlaylist(newTracks)
        }
        
        private func extractTrackInfo(from url: URL) async -> AudioTrack {
            let asset = AVAsset(url: url)
            
            let fileName = url.deletingPathExtension().lastPathComponent
            var title = fileName
            var artist = "Unknown Artist"
            var artwork: UIImage?
            var duration: TimeInterval = 0
            
            do {
                duration = try await asset.load(.duration).seconds
                
                let metadata = asset.commonMetadata
                
                for item in metadata {
                    guard let key = item.commonKey else { continue }
                    
                    switch key {
                    case .commonKeyTitle:
                        if let value = item.stringValue {
                            title = value
                        }
                    case .commonKeyArtist:
                        if let value = item.stringValue {
                            artist = value
                        }
                    case .commonKeyArtwork:
                        if let data = item.dataValue {
                            artwork = UIImage(data: data)
                        }
                    default:
                        break
                    }
                }
            } catch {
                print("Error loading metadata: \(error)")
            }
            
            return AudioTrack(title: title, artist: artist, url: url, artwork: artwork, duration: duration)
        }
    }
}
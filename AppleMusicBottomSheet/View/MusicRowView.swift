//
//  MusicRowView.swift
//  AppleMusicBottomSheet
//
//  Created by Claude on 28/06/25.
//

import SwiftUI

struct MusicRowView: View {
    let track: AudioTrack
    @EnvironmentObject var audioManager: AudioManager
    
    var body: some View {
        HStack {
            // Artwork
            if let artwork = track.artwork {
                Image(uiImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .overlay {
                        Image(systemName: "music.note")
                            .foregroundColor(.gray)
                    }
            }
            
            // Track Info
            VStack(alignment: .leading, spacing: 2) {
                Text(track.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(track.artist)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                if track.duration > 0 {
                    Text(formatDuration(track.duration))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Playing indicator
            if audioManager.currentTrack?.id == track.id {
                if audioManager.isPlaying {
                    Image(systemName: "speaker.wave.2.fill")
                        .foregroundColor(.blue)
                        .font(.caption)
                } else {
                    Image(systemName: "pause.fill")
                        .foregroundColor(.blue)
                        .font(.caption)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
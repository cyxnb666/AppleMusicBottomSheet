//
//  MusicInfo.swift
//  AppleMusicBottomSheet
//
//  Created by Balaji on 18/03/23.
//

import SwiftUI

/// Resuable File
struct MusicInfo: View {
    @Binding var expandSheet: Bool
    var animation: Namespace.ID
    @ObservedObject var audioManager: AudioManager
    var body: some View {
        HStack(spacing: 0) {
            /// Adding Matched Geometry Effect (Hero Animation)
            ZStack {
                if !expandSheet {
                    GeometryReader {
                        let size = $0.size
                        
                        if let artwork = audioManager.currentTrack?.artwork {
                            Image(uiImage: artwork)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: size.width, height: size.height)
                                .clipShape(RoundedRectangle(cornerRadius: expandSheet ? 15 : 5, style: .continuous))
                        } else {
                            Image("Artwork")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: size.width, height: size.height)
                                .clipShape(RoundedRectangle(cornerRadius: expandSheet ? 15 : 5, style: .continuous))
                        }
                    }
                    .matchedGeometryEffect(id: "ARTWORK", in: animation)
                }
            }
            .frame(width: 45, height: 45)
            
            Text(audioManager.currentTrack?.title ?? "No Track Playing")
                .fontWeight(.semibold)
                .lineLimit(1)
                .padding(.horizontal, 15)
            
            Spacer(minLength: 0)
            
            Button {
                audioManager.togglePlayPause()
            } label: {
                Image(systemName: audioManager.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title2)
            }
            
            Button {
                audioManager.nextTrack()
            } label: {
                Image(systemName: "forward.fill")
                    .font(.title2)
            }
            .padding(.leading, 25)
        }
        .foregroundColor(.primary)
        .padding(.horizontal)
        .padding(.bottom, 5)
        .frame(height: 70)
        .contentShape(Rectangle())
        .onTapGesture {
            /// Expanding Bottom Sheet
            withAnimation(.easeInOut(duration: 0.3)) {
                expandSheet = true
            }
        }
    }
}

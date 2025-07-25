//
//  ExpandedBottomSheet.swift
//  AppleMusicBottomSheet
//
//  Created by Balaji on 18/03/23.
//

import SwiftUI

struct ExpandedBottomSheet: View {
    @Binding var expandSheet: Bool
    var animation: Namespace.ID
    @ObservedObject var audioManager: AudioManager
    /// View Properties
    @State private var animateContent: Bool = false
    @State private var offsetY: CGFloat = 0
    var body: some View {
        GeometryReader {
            let size = $0.size
            let safeArea = $0.safeAreaInsets
            let dragProgress = 1.0 - (offsetY / (size.height * 0.5))
            let cornerProgress = max(0, dragProgress)
            
            ZStack {
                /// Making it as Rounded Rectangle with Device Corner Radius
                RoundedRectangle(cornerRadius: animateContent ? deviceCornerRadius * cornerProgress : 0, style: .continuous)
                    .fill(.ultraThickMaterial)
                    .overlay(content: {
                        RoundedRectangle(cornerRadius: animateContent ? deviceCornerRadius * cornerProgress : 0, style: .continuous)
                            .fill(Color("BG"))
                            .opacity(animateContent ? 1 : 0)
                    })
                    .overlay(alignment: .top) {
                        MusicInfo(expandSheet: $expandSheet, animation: animation, audioManager: audioManager)
                        /// Disabling Interaction (Since it's not Necessary Here)
                            .allowsHitTesting(false)
                            .opacity(animateContent ? 0 : 1)
                    }
                    .matchedGeometryEffect(id: "BGVIEW", in: animation)
                
                
                VStack(spacing: 15) {
                    /// Grab Indicator
                    Capsule()
                        .fill(.gray)
                        .frame(width: 40, height: 5)
                        .opacity(animateContent ? cornerProgress : 0)
                        /// Mathing with Slide Animation
                        .offset(y: animateContent ? 0 : size.height)
                        .clipped()
                    
                    /// Artwork Hero View
                    GeometryReader {
                        let size = $0.size
                        
                        if let artwork = audioManager.currentTrack?.artwork {
                            Image(uiImage: artwork)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: size.width, height: size.height)
                                .clipShape(RoundedRectangle(cornerRadius: animateContent ? 15 : 5, style: .continuous))
                        } else {
                            Image("Artwork")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: size.width, height: size.height)
                                .clipShape(RoundedRectangle(cornerRadius: animateContent ? 15 : 5, style: .continuous))
                        }
                    }
                    .matchedGeometryEffect(id: "ARTWORK", in: animation)
                    /// For Square Artwork Image
                    .frame(height: size.width - 50)
                    /// For Smaller Devices the padding will be 10 and for larger devices the padding will be 30
                    .padding(.vertical, size.height < 700 ? 10 : 30)
                    
                    /// Player View
                    PlayerView(size)
                    /// Moving it From Bottom
                        .offset(y: animateContent ? 0 : size.height)
                }
                .padding(.top, safeArea.top + (safeArea.bottom == 0 ? 10 : 0))
                .padding(.bottom, safeArea.bottom == 0 ? 10 : safeArea.bottom)
                .padding(.horizontal, 25)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .clipped()
            }
            .contentShape(Rectangle())
            .offset(y: offsetY)
            .gesture(
                DragGesture()
                    .onChanged({ value in
                        let translationY = value.translation.height
                        offsetY = (translationY > 0 ? translationY : 0)
                    }).onEnded({ value in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            if (offsetY + (value.velocity.height * 0.3)) > size.height * 0.4 {
                                expandSheet = false
                                animateContent = false
                                offsetY = .zero
                            } else {
                                offsetY = .zero
                            }
                        }
                    })
            )
            .ignoresSafeArea(.container, edges: .all)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.35)) {
                animateContent = true
            }
        }
    }
    
    /// Player View (containing all the song information with playback controls)
    @ViewBuilder
    func PlayerView(_ mainSize: CGSize) -> some View {
        GeometryReader {
            let size = $0.size
            /// Dynamic Spacing Using Available Height
            let spacing = size.height * 0.04
            
            /// Sizing it for more compact look
            VStack(spacing: spacing) {
                VStack(spacing: spacing) {
                    HStack(alignment: .center, spacing: 15) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(audioManager.currentTrack?.title ?? "No Track Playing")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            Text(audioManager.currentTrack?.artist ?? "Unknown Artist")
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Button {
                            
                        } label: {
                            Image(systemName: "ellipsis")
                                .foregroundColor(.white)
                                .padding(12)
                                .background {
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .environment(\.colorScheme, .light)
                                }
                        }

                    }
                    
                    /// Timing Indicator
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .environment(\.colorScheme, .light)
                            .frame(height: 5)
                        
                        Capsule()
                            .fill(.white)
                            .frame(width: max(0, CGFloat(audioManager.currentTime / max(audioManager.duration, 1)) * (size.width - 50)), height: 5)
                    }
                    .padding(.top, spacing)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let progress = min(max(0, value.location.x / (size.width - 50)), 1)
                                let newTime = progress * audioManager.duration
                                audioManager.seek(to: newTime)
                            }
                    )
                    
                    /// Timing Label View
                    HStack {
                        Text(formatTime(audioManager.currentTime))
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Spacer(minLength: 0)
                        
                        Text(formatTime(audioManager.duration))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                /// Moving it to Top
                .frame(height: size.height / 2.5, alignment: .top)
                
                /// Playback Controls
                HStack(spacing: size.width * 0.18) {
                    Button {
                        audioManager.previousTrack()
                    } label: {
                        Image(systemName: "backward.fill")
                        /// Dynamic Sizing for Smaller to Larger iPhones
                            .font(size.height < 300 ? .title3 : .title)
                    }
                    
                    /// Making Play/Pause Little Bigger
                    Button {
                        audioManager.togglePlayPause()
                    } label: {
                        Image(systemName: audioManager.isPlaying ? "pause.fill" : "play.fill")
                        /// Dynamic Sizing for Smaller to Larger iPhones
                            .font(size.height < 300 ? .largeTitle : .system(size: 50))
                    }
                    
                    Button {
                        audioManager.nextTrack()
                    } label: {
                        Image(systemName: "forward.fill")
                        /// Dynamic Sizing for Smaller to Larger iPhones
                            .font(size.height < 300 ? .title3 : .title)
                    }
                }
                .foregroundColor(.white)
                .frame(maxHeight: .infinity)
                
                /// Volume & Other Controls
                VStack(spacing: spacing) {
                    HStack(spacing: 15) {
                        Image(systemName: "speaker.fill")
                            .foregroundColor(.gray)
                        
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(.ultraThinMaterial)
                                .environment(\.colorScheme, .light)
                                .frame(height: 5)
                            
                            Capsule()
                                .fill(.white)
                                .frame(width: CGFloat(audioManager.volume) * (size.width - 80), height: 5)
                        }
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let progress = min(max(0, value.location.x / (size.width - 80)), 1)
                                    audioManager.setVolume(Float(progress))
                                }
                        )
                        
                        Image(systemName: "speaker.wave.3.fill")
                            .foregroundColor(.gray)
                    }
                    
                    HStack(alignment: .top, spacing: size.width * 0.18) {
                        Button {
                            
                        } label: {
                            Image(systemName: "quote.bubble")
                                .font(.title2)
                        }
                        
                        VStack(spacing: 6) {
                            Button {
                                
                            } label: {
                                Image(systemName: "airpods.gen3")
                                    .font(.title2)
                            }
                            
                            Text("iJustine's Airpods")
                                .font(.caption)
                        }
                        
                        Button {
                            
                        } label: {
                            Image(systemName: "list.bullet")
                                .font(.title2)
                        }
                    }
                    .foregroundColor(.white)
                    .blendMode(.overlay)
                    .padding(.top, spacing)
                }
                /// Moving it to bottom
                .frame(height: size.height / 2.5, alignment: .bottom)
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct ExpandedBottomSheet_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .preferredColorScheme(.dark)
    }
}

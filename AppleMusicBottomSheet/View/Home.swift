//
//  Home.swift
//  AppleMusicBottomSheet
//
//  Created by Balaji on 18/03/23.
//

import SwiftUI

struct Home: View {
    /// Animation Properties
    @State private var expandSheet: Bool = false
    @State private var hideTabBar: Bool = false
    @Namespace private var animation
    @StateObject private var audioManager = AudioManager()
    @StateObject private var musicLibrary = MusicLibrary()
    @State private var showingDocumentPicker = false
    var body: some View {
        /// Tab View
        TabView {
            ListenNow()
                .setTabItem("Listen Now", "play.circle.fill")
                .setTabBarBackground(.init(.ultraThickMaterial))
                .hideTabBar(hideTabBar)
            /// Sample Tab's
            SampleTab("Browse", "square.grid.2x2.fill")
            SampleTab("Radio", "dot.radiowaves.left.and.right")
            MusicLibraryView()
                .setTabItem("Music", "play.square.stack")
                .setTabBarBackground(.init(.ultraThickMaterial))
                .hideTabBar(hideTabBar)
            SampleTab("Search", "magnifyingglass")
        }
        /// Changing Tab Indicator Color
        .tint(.red)
        .safeAreaInset(edge: .bottom) {
            CustomBottomSheet()
        }
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPickerView(musicLibrary: musicLibrary, audioManager: audioManager)
        }
        .environmentObject(audioManager)
        .environmentObject(musicLibrary)
        .onAppear {
            if !musicLibrary.tracks.isEmpty && audioManager.playlist.isEmpty {
                audioManager.addToPlaylist(musicLibrary.tracks)
            }
        }
        .overlay {
            if expandSheet {
                ExpandedBottomSheet(expandSheet: $expandSheet, animation: animation, audioManager: audioManager)
                /// Transition for direct slide down closing
                    .transition(.asymmetric(insertion: .identity, removal: .move(edge: .bottom)))
            }
        }
        .onChange(of: expandSheet) { newValue in
            /// Delaying a Little Bit for Hiding the Tab Bar
            DispatchQueue.main.asyncAfter(deadline: .now() + (newValue ? 0.04 : 0.03)) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    hideTabBar = newValue
                }
            }
        }
    }
    
    /// Custom Listen Now View
    @ViewBuilder
    func ListenNow() -> some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    Image("Card 1")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    
                    Image("Card 2")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
                .padding()
                .padding(.bottom, 100)
            }
            .navigationTitle("Listen Now")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        VStack {
                            
                        }
                        .navigationTitle("Account Info")
                    } label: {
                        Image(systemName: "person.circle.fill")
                            .font(.title3)
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingDocumentPicker = true
                    } label: {
                        Image(systemName: "music.note.list")
                            .font(.title3)
                    }
                }
            }
        }
    }
    
    /// Custom Bottom Sheet
    @ViewBuilder
    func CustomBottomSheet() -> some View {
        /// Animating Sheet Background (To Look Like It's Expanding From the Bottom)
        ZStack {
            if expandSheet {
                Rectangle()
                    .fill(.clear)
            } else {
                Rectangle()
                    .fill(.ultraThickMaterial)
                    .overlay {
                        /// Music Info
                        MusicInfo(expandSheet: $expandSheet, animation: animation, audioManager: audioManager)
                    }
                    .matchedGeometryEffect(id: "BGVIEW", in: animation)
                    /// Scale effect for visual deception during closing
                    .scaleEffect(expandSheet ? 1.05 : 1.0)
                    .animation(.easeOut(duration: 0.25), value: expandSheet)
            }
        }
        .frame(height: 70)
        /// Separator Line
        .overlay(alignment: .bottom, content: {
            Rectangle()
                .fill(.gray.opacity(0.3))
                .frame(height: 1)
        })
        /// 49: Default Tab Bar Height
        .offset(y: -49)
    }
    
    /// Music Library View
    @ViewBuilder
    func MusicLibraryView() -> some View {
        NavigationStack {
            if musicLibrary.tracks.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "music.note")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No Music Added")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Import music files to get started")
                        .foregroundColor(.secondary)
                    
                    Button {
                        showingDocumentPicker = true
                    } label: {
                        Text("Import Music")
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(.blue)
                            .cornerRadius(8)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(Array(musicLibrary.tracks.enumerated()), id: \.element.id) { index, track in
                        MusicRowView(track: track)
                            .onTapGesture {
                                audioManager.setPlaylist(musicLibrary.tracks, startIndex: index)
                                audioManager.play()
                            }
                    }
                    .onDelete { indexSet in
                        // 检查是否删除当前播放的歌曲
                        for index in indexSet {
                            if let currentTrack = audioManager.currentTrack,
                               musicLibrary.tracks[index].id == currentTrack.id {
                                // 停止播放
                                audioManager.pause()
                            }
                        }
                        
                        // 删除歌曲
                        musicLibrary.deleteTracks(at: indexSet)
                        
                        // 更新播放列表
                        if !musicLibrary.tracks.isEmpty {
                            audioManager.setPlaylist(musicLibrary.tracks)
                        } else {
                            // 如果没有歌曲了，清空播放列表
                            audioManager.playlist.removeAll()
                            audioManager.clearCurrentTrack()
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .navigationTitle("Music")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if !musicLibrary.tracks.isEmpty {
                    EditButton()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingDocumentPicker = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title3)
                }
            }
        }
    }
    
    /// Generates Sample View with Tab Label
    @ViewBuilder
    func SampleTab(_ title: String, _ icon: String) -> some View {
        /// iOS Bug, It can be Avoided by wrapping the view inside ScrollView
        ScrollView(.vertical, showsIndicators: false, content: {
            Text(title)
                .padding(.top, 25)
        })
        .setTabItem(title, icon)
        /// Changing Tab Background Color
        .setTabBarBackground(.init(.ultraThickMaterial))
        /// Hiding Tab Bar When Sheet is Expanded
        .hideTabBar(hideTabBar)
    }
}

struct Home_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .preferredColorScheme(.dark)
    }
}

/// Custom View Modifier's
extension View {
    @ViewBuilder
    func setTabItem(_ title: String, _ icon: String) -> some View {
        self
            .tabItem {
                Image(systemName: icon)
                Text(title)
            }
    }
    
    @ViewBuilder
    func setTabBarBackground(_ style: AnyShapeStyle) -> some View {
        self
            .toolbarBackground(.visible, for: .tabBar)
            .toolbarBackground(style, for: .tabBar)
    }
    
    @ViewBuilder
    func hideTabBar(_ status: Bool) -> some View {
        self
            .toolbar(status ? .hidden : .visible, for: .tabBar)
    }
}

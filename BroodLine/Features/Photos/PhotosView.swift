//
//  PhotosView.swift
//  BroodLine
//

import SwiftUI
import UIKit

enum PhotoFilter: String, CaseIterable, Identifiable, Hashable {
    case all, sire, dam, brood, award
    var id: String { rawValue }
    var label: String { self == .all ? "All" : rawValue.capitalized }
    var category: PhotoCategory? { self == .all ? nil : PhotoCategory(rawValue: rawValue) }
}

struct PhotosView: View {
    @EnvironmentObject var store: DataStore
    @State private var filter: PhotoFilter = .all
    @State private var showCategorySheet = false
    @State private var showPicker = false
    @State private var pendingCategory: PhotoCategory = .brood
    @State private var compareMode = false
    @State private var compareIDs: [UUID] = []
    @State private var showCompare = false
    @State private var fullScreen: PhotoItem?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 2)

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    ChipPicker(items: PhotoFilter.allCases, label: { $0.label }, selection: $filter)
                    if compareMode {
                        Text("Select two photos to compare (\(compareIDs.count)/2)")
                            .font(AppFont.caption()).foregroundColor(Palette.copper)
                    }

                    let photos = filtered
                    if photos.isEmpty {
                        EmptyStateView(icon: "photo.on.rectangle.angled",
                                       title: "No photos",
                                       message: "Capture sires, dams, broods and awards to compare them later.",
                                       actionTitle: "Add Photo") { showCategorySheet = true }
                    } else {
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(photos) { photo in
                                photoCell(photo)
                            }
                        }
                    }
                    TabBarSpacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
            }
        }
        .navigationBarTitle("Photos", displayMode: .inline)
        .navigationBarItems(trailing: HStack(spacing: 16) {
            Button { toggleCompare() } label: {
                Image(systemName: compareMode ? "rectangle.split.2x1.fill" : "rectangle.split.2x1")
                    .foregroundColor(compareMode ? Palette.copper : Palette.primary)
            }
            Button { showCategorySheet = true } label: {
                Image(systemName: "plus").font(.system(size: 17, weight: .semibold)).foregroundColor(Palette.primary)
            }
        })
        .actionSheet(isPresented: $showCategorySheet) {
            ActionSheet(title: Text("Photo category"), buttons: [
                .default(Text("Sire")) { pick(.sire) },
                .default(Text("Dam")) { pick(.dam) },
                .default(Text("Brood")) { pick(.brood) },
                .default(Text("Award")) { pick(.award) },
                .cancel()
            ])
        }
        .sheet(isPresented: $showPicker) {
            PhotoPicker { image in
                store.addPhoto(image: image, category: pendingCategory, relatedID: nil, caption: pendingCategory.label)
            }
        }
        .sheet(isPresented: $showCompare) { compareSheet }
        .sheet(item: $fullScreen) { photo in fullScreenView(photo) }
    }

    private var filtered: [PhotoItem] {
        store.photos.filter { filter.category == nil || $0.category == filter.category }
    }

    private func photoCell(_ photo: PhotoItem) -> some View {
        let selected = compareIDs.contains(photo.id)
        return Button {
            if compareMode { toggleSelect(photo) } else { fullScreen = photo }
        } label: {
            ZStack(alignment: .topTrailing) {
                Group {
                    if let image = ImageStorage.load(photo.filename) {
                        Image(uiImage: image).resizable().scaledToFill()
                    } else {
                        ZStack { Palette.bgSoft; Image(systemName: "photo").foregroundColor(Palette.textDisabled) }
                    }
                }
                .frame(height: 150).frame(maxWidth: .infinity).clipped()
                .overlay(
                    VStack { Spacer()
                        HStack {
                            Text(photo.caption.isEmpty ? photo.category.label : photo.caption)
                                .font(AppFont.caption(11)).foregroundColor(.white).lineLimit(1)
                            Spacer()
                        }
                        .padding(8)
                        .background(LinearGradient(colors: [.black.opacity(0.6), .clear], startPoint: .bottom, endPoint: .top))
                    }
                )
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(selected ? Palette.copper : photo.category.color.opacity(0.6), lineWidth: selected ? 3 : 1))

                if compareMode {
                    Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(selected ? Palette.copper : .white)
                        .padding(8)
                }
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .contextMenu {
            Button { store.deletePhoto(photo) } label: { Label("Delete", systemImage: "trash") }
        }
    }

    private func fullScreenView(_ photo: PhotoItem) -> some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 16) {
                if let image = ImageStorage.load(photo.filename) {
                    Image(uiImage: image).resizable().scaledToFit()
                }
                Text(photo.caption).font(AppFont.headline(16)).foregroundColor(.white)
                Button("Close") { fullScreen = nil }.foregroundColor(Palette.primary)
            }
            .padding()
        }
    }

    private var compareSheet: some View {
        let items = compareIDs.compactMap { id in store.photos.first { $0.id == id } }
        return ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 12) {
                Text("Compare").font(AppFont.title(20)).foregroundColor(.white).padding(.top, 20)
                HStack(spacing: 10) {
                    ForEach(items) { photo in
                        VStack(spacing: 8) {
                            if let image = ImageStorage.load(photo.filename) {
                                Image(uiImage: image).resizable().scaledToFit().cornerRadius(12)
                            }
                            Text(photo.caption.isEmpty ? photo.category.label : photo.caption)
                                .font(AppFont.caption()).foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 12)
                Spacer()
                Button("Done") { showCompare = false; compareIDs = []; compareMode = false }
                    .foregroundColor(Palette.primary).padding(.bottom, 24)
            }
        }
    }

    private func toggleCompare() {
        withAnimation { compareMode.toggle(); compareIDs = [] }
    }
    private func toggleSelect(_ photo: PhotoItem) {
        if let idx = compareIDs.firstIndex(of: photo.id) {
            compareIDs.remove(at: idx)
        } else if compareIDs.count < 2 {
            compareIDs.append(photo.id)
            if compareIDs.count == 2 { showCompare = true }
        }
    }
    private func pick(_ category: PhotoCategory) {
        pendingCategory = category
        showPicker = true
    }
}


struct OfflineComb: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image("lines_e")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea()
                    .opacity(0.9)
                    .blur(radius: 3)
                
                errorView
            }
        }
        .ignoresSafeArea()
    }
    
    private var errorView: some View {
        Image("linesee")
            .resizable()
            .frame(width: 320, height: 260)
    }
}

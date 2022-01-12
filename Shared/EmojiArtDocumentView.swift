//
//  EmojiArtDocumentView.swift
//  EmojiArt
//
//  Created by Sankarshana V on 2022/01/03.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    typealias Model = EmojiArtModel
    @ObservedObject var document: EmojiArtDocument
    @ScaledMetric var defaultEmojiFontSize: CGFloat = 40
    @Environment(\.undoManager) var undoManager
    
    var body: some View {
        VStack(spacing: 0) {
            documentBody
            PaletteChooser(emojiFontSize: defaultEmojiFontSize)
        }
    }
    
    var documentBody: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white
                
                OptionalImage(uiImage: document.backgroundImage)
                    .scaleEffect(zoomScale)
                    .position(convertFromEmojisCoordinates((0, 0), in: geometry)) // position at the center
                    .gesture(doubleTapToZoom(in: geometry.size))
                
                if document.backgroundImageFetchStatus == .fetching { // loading view
                    ProgressView()
                        .scaleEffect(2)
                } else {
                    ForEach(document.emojis) { emoji in
                        Text(emoji.text)
                            .font(.system(size: fontSize(for: emoji)))
                            .scaleEffect(zoomScale)
                            .position(position(for: emoji, in: geometry))
                    }
                }
            }
            .clipped()
            .onDrop(of: [.utf8PlainText, .url, .image], isTargeted: nil) { providers, location in
                drop(providers: providers, at: location, in: geometry)
            }
            .gesture(zoomGesture().simultaneously(with: panGesture()))
            .alert(item: $alertToShow) { alertToShow in
                alertToShow.alert()
            }
            .onChange(of: document.backgroundImageFetchStatus) { status in
                switch (status) {
                case .failed(let url):
                    showBackgroundImageFailedAlert(url)
                default: break
                }
            }
            .onReceive(document.$backgroundImage) { image in
                if autozoom {
                    zoomToFit(image, in: geometry.size)
                }
            }
            .compactableToolbar {
                AnimatedActionButton(title: "Paste Background", systemImage: "doc.on.clipboard") {
                    pasteBackground()
                }
                
                if Camera.isAvailable {
                    AnimatedActionButton(title: "Camera", systemImage: "camera") {
                        backgroundPicker = .camera
                    }
                }
                
                if PhotoLibrary.isAvailable {
                    AnimatedActionButton(title: "Search Photos", systemImage: "photo") {
                        backgroundPicker = .library
                    }
                }
                
                #if os(iOS)
                if let undoManager = undoManager {
                    if undoManager.canUndo {
                        AnimatedActionButton(title: undoManager.undoActionName, systemImage: "arrow.uturn.backward") {
                            undoManager.undo()
                        }
                    }
                    
                    if undoManager.canRedo {
                        AnimatedActionButton(title: undoManager.redoActionName, systemImage: "arrow.uturn.forward") {
                            undoManager.redo()
                        }
                    }
                }
                #endif
            }
            .sheet(item: $backgroundPicker) { pickerType in
                switch pickerType {
                case .camera: Camera(handlePickedImage: { image in handlePickedBackgroundImage(image) })
                case .library: EmptyView()
                }
            }
        }
    }
    
    @State private var backgroundPicker: BackgroundPickerType?
    
    private func handlePickedBackgroundImage(_ image: UIImage?) {
        autozoom = true
        if let imageData = image?.imageData {
            document.setBackground(.imageData(imageData), undoManager: undoManager)
        }
        backgroundPicker = nil
    }
    
    enum BackgroundPickerType: Identifiable {
        case camera
        case library
        var id: BackgroundPickerType { self }
    }
    
    private func pasteBackground() {
        autozoom = true
        if let imageData = Pasteboard.imageData {
            document.setBackground(.imageData(imageData), undoManager: undoManager)
        } else if let url = Pasteboard.imageURL {
            document.setBackground(.url(url), undoManager: undoManager)
        } else {
            alertToShow = IdentifiableAlert(
                title: "Paste Background",
                message: "There isn't any image data currently copied!"
            )
        }
    }
    
    @State private var autozoom = false
    
    @State private var alertToShow: IdentifiableAlert?
    
    private func showBackgroundImageFailedAlert(_ url: URL) {
        alertToShow = IdentifiableAlert(id: "fetch failed: \(url.absoluteString).") {
            Alert(
                title: Text("Error"),
                message: Text("Could not fetch the background image."),
                dismissButton: .default(Text("Okay"))
            )
        }
    }
    
    private func drop(providers: [NSItemProvider], at location: CGPoint, in geometry: GeometryProxy) -> Bool {
        // for urls
        var found = providers.loadObjects(ofType: URL.self) { url in
            autozoom = true
            document.setBackground(.url(url.imageURL), undoManager: undoManager)
        }
        
        if found {
            return true
        }
        #if os(iOS)
        // for images
        found = providers.loadObjects(ofType: UIImage.self) { image in
            if let data = image.jpegData(compressionQuality: 1.0) {
                autozoom = true
                document.setBackground(.imageData(data), undoManager: undoManager)
            }
        }
        #endif
        if found {
            return true
        }
        
        // for emojis
        found = providers.loadObjects(ofType: String.self) { string in
            if let emojiCharacter = string.first, emojiCharacter.isEmoji {
                document.addEmoji(
                    String(emojiCharacter),
                    at: convertToEmojiCoordinates(location, in: geometry),
                    size: defaultEmojiFontSize / zoomScale,
                    undoManager: undoManager
                )
            }
        }
        
        return found
    }
    
    private func fontSize(for emoji: Model.Emoji) -> CGFloat {
        CGFloat(emoji.size)
    }
    
    // For Drag
    @SceneStorage("EmojiArtDocumentView.steadyStatePanOffset")
    private var steadyStatePanOffset = CGSize.zero
    @GestureState private var gesturePanOffset = CGSize.zero
    
    private var panOffset: CGSize {
        (steadyStatePanOffset + gesturePanOffset) * zoomScale
    }
    
    private func panGesture() -> some Gesture {
        // Non-discrete gesture as well!!
        DragGesture()
            .onEnded { finalDragGestureValue in
                steadyStatePanOffset = steadyStatePanOffset + (finalDragGestureValue.translation / zoomScale)
            }
            .updating($gesturePanOffset) { latestDragGestureValue, gesturePanOffsetInOut, transaction in
                gesturePanOffsetInOut = latestDragGestureValue.translation / zoomScale
            }
    }
    
    // For Zoom
    @SceneStorage("EmojiArtDocumentView.steadyStateZoomScale")
    private var steadyStateZoomScale: CGFloat = 1
    @GestureState private var gestureZoomScale: CGFloat = 1
    
    private var zoomScale: CGFloat {
        steadyStateZoomScale * gestureZoomScale
    }
    
    private func zoomGesture() -> some Gesture {
        // Non-discrete gesture!!
        MagnificationGesture()
            .updating($gestureZoomScale) { latestGestureZoomScale, gestureZoomScaleInOut, transaction in
                gestureZoomScaleInOut = latestGestureZoomScale
            }
            .onEnded { gestureScaleAtEnd in
                steadyStateZoomScale *= gestureScaleAtEnd
            }
    }
    
    private func zoomToFit(_ image: UIImage?, in size: CGSize) {
        // [size] here is the size of the view on screen
        if let image = image, image.size.width > 0, image.size.height > 0, size.width > 0, size.height > 0 {
            let hZoom = size.width / image.size.width
            let vZoom = size.height / image.size.height
            
            steadyStateZoomScale = min(hZoom, vZoom)
        }
    }
    
    private func doubleTapToZoom(in size: CGSize) -> some Gesture {
        // Discrete Gesture
        TapGesture(count: 2)
            .onEnded {
                withAnimation {
                    zoomToFit(document.backgroundImage, in: size)
                }
            }
    }
    
    private func position(for emoji: Model.Emoji, in geometry: GeometryProxy) -> CGPoint {
        convertFromEmojisCoordinates((emoji.x, emoji.y), in: geometry)
    }
    
    private func convertFromEmojisCoordinates(_ emojisLocation: (x: Int, y: Int), in geometry: GeometryProxy) -> CGPoint {
        let center = geometry.frame(in: .local).center
        
        return CGPoint(
            x: center.x + CGFloat(emojisLocation.x) * zoomScale + panOffset.width,
            y: center.y + CGFloat(emojisLocation.y) * zoomScale + panOffset.height
        )
    }
    
    private func convertToEmojiCoordinates(_ location: CGPoint, in geometry: GeometryProxy) -> (x: Int, y: Int) {
        let center = geometry.frame(in: .local).center
        
        let convertedLocation = CGPoint(
            x: (location.x - center.x - panOffset.width) / zoomScale,
            y: (location.y - center.y - panOffset.height) / zoomScale
        )
        
        return (Int(convertedLocation.x), Int(convertedLocation.y))
    }
}



















struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        EmojiArtDocumentView(document: EmojiArtDocument())
    }
}

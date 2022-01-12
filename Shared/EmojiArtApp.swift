//
//  EmojiArtApp.swift
//  Shared
//
//  Created by Sankarshana V on 2022/01/10.
//

import SwiftUI

@main
struct EmojiArtApp: App {
    // ViewModels:
    @StateObject var paletteStore = PaletteStore(named: "Default")
    
    var body: some Scene {
        DocumentGroup(newDocument: { EmojiArtDocument() }) { config in
            EmojiArtDocumentView(document: config.document)
                .environmentObject(paletteStore)
        }
    }
}


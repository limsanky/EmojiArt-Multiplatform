//
//  EmojiArtApp.swift
//  Shared
//
//  Created by Sankarshana V on 2022/01/10.
//

import SwiftUI

@main
struct EmojiArtApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: EmojiArtDocument()) { file in
            ContentView(document: file.$document)
        }
    }
}

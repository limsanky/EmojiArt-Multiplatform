//
//  iOS.swift
//  EmojiArt (iOS)
//
//  Created by Sankarshana V on 2022/01/12.
//

import SwiftUI

extension View {
    
    func popoverPadding() -> some View {
        self
    }
    
    func paletteControlButtonStyle() -> some View {
        self
    }
    
    @ViewBuilder
    func wrappedInNavigationViewToMakeDismissable(_ dismiss: (() -> Void)?) -> some View {
        if UIDevice.current.userInterfaceIdiom != .pad, let dismiss = dismiss {
            NavigationView {
                self
                    .navigationBarTitleDisplayMode(.inline)
                    .dismissable(dismiss)
            }
        } else {
                self
            }
        }
    
    @ViewBuilder
    func dismissable(_ dismiss: (() -> Void)?) -> some View {
        if UIDevice.current.userInterfaceIdiom != .pad, let dismiss = dismiss {
            self.toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        } else {
            self
        }
    }
}

extension UIImage {
    var imageData: Data? {
        jpegData(compressionQuality: 1.0)
    }
}

struct Pasteboard {
    static var imageData: Data? {
        UIPasteboard.general.image?.imageData
    }
    
    static var imageURL: URL {
        UIPasteboard.general.url?.imageURL
    }
}

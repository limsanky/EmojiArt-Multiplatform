//
//  EmojiArtModel.swift
//  EmojiArt
//
//  Created by Sankarshana V on 2022/01/03.
//

import Foundation

struct EmojiArtModel: Codable {
    var background = Background.blank
    var emojis = [Emoji]()
    
    struct Emoji: Identifiable, Hashable, Codable {
        let text: String // the emoji itself, which can't be changed
        
        // X and Y coordinates
        var x: Int // x-axis offset from the center
        var y: Int // y-axis offset from the center
        
        // The size
        var size: Int
        
        let id: Int
        
        // No one can create an Emoji, except us.
        fileprivate init(text: String, x: Int, y: Int, size: Int, id: Int) {
            self.text = text
            self.x = x
            self.y = y
            self.id = id
            self.size = size
        }
    }
    
    // Empty Init, the free init provided is replaced so that no one can create a model with custom emojis
    init() { }
    
    init(json: Data) throws {
        self = try JSONDecoder().decode(EmojiArtModel.self, from: json)
    }
    
    init(url: URL) throws {
        let data = try Data(contentsOf: url)
        self = try EmojiArtModel(json: data)
    }
    
    func json() throws -> Data {
        try JSONEncoder().encode(self)
    }
    
    private var uniqueEmojiId = 0
    
    mutating func addEmoji(_ text: String, at location: (x: Int, y: Int), size: Int) {
        uniqueEmojiId += 1
        emojis.append(Emoji(text: text, x: location.x, y: location.y, size: size, id: uniqueEmojiId))
    }
}

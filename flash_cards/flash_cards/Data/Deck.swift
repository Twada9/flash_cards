//
//  Deck.swift
//  flash_cards
//
//  Created by wada on 2025/11/23.
//

import Foundation

// Deckモデルはすでに定義されているので、IDを明示的に設定できるよう修正します
struct Deck: Identifiable, Equatable {
    var id: UUID
    var title: String
    
    init(id: UUID = UUID(), title: String) {
        self.id = id
        self.title = title
    }
}

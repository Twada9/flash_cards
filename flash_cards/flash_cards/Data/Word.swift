//
//  Word.swift
//  flash_cards
//
//  Created by wada on 2025/11/23.
//

import Foundation

// 単語を表す構造体
struct Word: Identifiable, Equatable {
    var id: UUID
    var term: String
    var definition: String
    
    init(id: UUID = UUID(), term: String, definition: String) {
        self.id = id
        self.term = term
        self.definition = definition
    }
}

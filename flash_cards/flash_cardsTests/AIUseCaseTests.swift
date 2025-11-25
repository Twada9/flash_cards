//
//  AIUseCaseTests.swift
//  flash_cardsTests
//
//  Created by wada on 2025/11/22.
//

import Testing
@testable import flash_cards

struct AIUseCaseTests {
//    init() {
//        aiUseCase = AIUseCase()
//    }
    
    @Test
    @available(iOS 26.0, *)
    func response() async throws {
        let aiUseCase = AIUseCase()
        try await aiUseCase.generateFlashCards(from: "Hello World", numberOfCards: 10)
        
    }

}

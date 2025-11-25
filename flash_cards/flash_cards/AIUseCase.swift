//
//  AIUseCase.swift
//  flash_cards
//
//  Created by wada on 2025/11/22.
//

import Foundation
import FoundationModels

@available(iOS 26.0, *)
class AIUseCase {
    private let model: SystemLanguageModel
    private let session: LanguageModelSession

    init(model: SystemLanguageModel = SystemLanguageModel.default, session: LanguageModelSession = LanguageModelSession()) {
        self.model = model
        self.session = session
    }

    
    func generateFlashCards(from topic: String, numberOfCards: Int) async throws {
        let prompt = """
        Create \(numberOfCards) flash cards about the topic "\(topic)". Each flash card should have a question and an answer. Format the output as JSON array with objects containing "question" and "answer" fields.
        """
        let response = try await session.respond(to: prompt)
        print(response)
        
//        let response = try await session.generateText(
//            model: model,
//            prompt: prompt,
//            maxTokens: 1000,
//            temperature: 0.7
//        )
        
//        guard let data = response.data(using: .utf8) else {
//            throw NSError(domain: "AIUseCase", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert response to data"])
//        }
//        
//        let decoder = JSONDecoder()
//        let flashCards = try decoder.decode([FlashCard].self, from: data)
//        return flashCards
    }
}

//
//  FlashCardView.swift
//  flash_cards
//
//  Created by wada on 2025/03/03.
//

import SwiftUI
import ComposableArchitecture

struct FlashCard: Reducer {
    struct State: Equatable {
        var words: [Word]
        var currentIndex: Int = 0
        var isShowingDefinition: Bool = false
        var isCompleted: Bool = false
        
        var currentWord: Word? {
            guard !words.isEmpty, currentIndex >= 0, currentIndex < words.count else {
                return nil
            }
            return words[currentIndex]
        }
        
        var hasNextCard: Bool {
            return !words.isEmpty && currentIndex < words.count - 1
        }
        
        var hasPreviousCard: Bool {
            return !words.isEmpty && currentIndex > 0
        }
        
        var isLastCard: Bool {
            return !words.isEmpty && currentIndex == words.count - 1
        }
    }
    
    enum Action {
        case nextCard
        case previousCard
        case toggleDefinition
        case resetCards
        case completeCards
        case dismissCompletion
        case close
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .nextCard:
                guard !state.words.isEmpty else { return .none }
                
                if state.isLastCard {
                    state.isCompleted = true
                } else if state.currentIndex < state.words.count - 1 {
                    state.currentIndex += 1
                    state.isShowingDefinition = false
                }
                return .none
                
            case .previousCard:
                guard state.hasPreviousCard else { return .none }
                state.currentIndex -= 1
                state.isShowingDefinition = false
                return .none
                
            case .toggleDefinition:
                guard state.currentWord != nil else { return .none }
                state.isShowingDefinition.toggle()
                return .none
                
            case .resetCards:
                guard !state.words.isEmpty else { return .none }
                state.currentIndex = 0
                state.isShowingDefinition = false
                state.isCompleted = false
                return .none
                
            case .completeCards:
                state.isCompleted = true
                return .none
                
            case .dismissCompletion:
                state.isCompleted = false
                return .none
                
            case .close:
                return .none
            }
        }
    }
}

struct FlashCardView: View {
    @Environment(\.dismiss) var dismiss
    let store: StoreOf<FlashCard>
    @State private var offset: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1
    @State private var opacity: Double = 1
    @State private var nextCardOpacity: Double = 0.5
    @State private var nextCardScale: Double = 0.8
    @State private var isRemoving: Bool = false
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            ZStack {
                VStack {
                    if viewStore.words.isEmpty {
                        Text("単語がありません")
                            .font(.title)
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        Spacer()
                        
                        // Card counter
                        Text("\(viewStore.currentIndex + 1) / \(viewStore.words.count)")
                            .font(.headline)
                            .padding(.top)
                        
                        // Flash card
                        ZStack {
                            // Next card preview (if available)
                            if viewStore.hasNextCard && !viewStore.isCompleted && viewStore.currentIndex + 1 < viewStore.words.count {
                                cardView(for: viewStore.words[viewStore.currentIndex + 1], isShowingDefinition: false)
                                    .scaleEffect(nextCardScale)
                                    .opacity(nextCardOpacity)
                                
                            }
                            if !isRemoving {
                                                    cardView(for: viewStore.currentWord, isShowingDefinition: viewStore.isShowingDefinition)
                                .zIndex(1)
                                .offset(x: offset)
                                .rotationEffect(.degrees(rotation))
                                .scaleEffect(scale)
                                .opacity(opacity)
                                .gesture(
                                    DragGesture()
                                        .onChanged { gesture in
                                            handleDragChanged(gesture, viewStore: viewStore)
                                        }
                                        .onEnded { gesture in
                                            handleDragEnded(gesture, viewStore: viewStore)
                                        }
                                )
                                .onTapGesture {
                                    viewStore.send(.toggleDefinition)
                                }
                                .transition(AnyTransition.offset(x: offset))
                        }
        
                            }
                            // Current card
                        
                        Spacer()
                        
                        // Navigation buttons
                        HStack {
                            Button(action: {
                                viewStore.send(.previousCard)
                            }) {
                                Image(systemName: "arrow.left.circle.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(viewStore.hasPreviousCard ? .blue : .gray)
                            }
                            .disabled(!viewStore.hasPreviousCard)
                            .padding()
                            
                            Spacer()
                            
                            Button(action: {
                                viewStore.send(.resetCards)
                            }) {
                                Image(systemName: "arrow.counterclockwise.circle.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.blue)
                            }
                            .padding()
                            
                            Spacer()
                            
                            Button(action: {
                                if viewStore.currentIndex == viewStore.words.count - 1 {
                                    viewStore.send(.completeCards)
                                } else {
                                    viewStore.send(.nextCard)
                                }
                            }) {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.blue)
                            }
                            .padding()
                        }
                        .padding(.bottom)
                    }
                }
                .navigationTitle("フラッシュカード")
                
                // 完了画面
                if viewStore.isCompleted {
                    Color(white: 0, opacity: 0.5)
                        .edgesIgnoringSafeArea(.all)
                        .transition(.opacity)
                    
                    VStack(spacing: 20) {
                        Text("お疲れ様でした！")
                            .font(.title)
                            .foregroundColor(.white)
                        
                        Button(action: {
                            viewStore.send(.resetCards)
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("もう一度テストする")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                        }
                        .padding(.bottom, 10)
                        
                        Button(action: {
                            viewStore.send(.close)
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "xmark")
                                Text("終了する")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.gray)
                            .cornerRadius(10)
                        }
                    }
                    .padding()
                    .background(Color(white: 0, opacity: 0.7))
                    .cornerRadius(20)
                    .transition(.opacity.combined(with: .scale))
                }
            }
            .animation(.easeInOut, value: viewStore.isCompleted)
        }
    }
    
    private func handleDragChanged(_ gesture: DragGesture.Value, viewStore: ViewStore<FlashCard.State, FlashCard.Action>) {
        offset = gesture.translation.width
        
        // カードの回転（オフセットに応じて-10度から10度）
//        rotation = Double(offset / 20)
        
        // スケールとオパシティの調整
        let dragPercentage = abs(offset / UIScreen.main.bounds.width)
        scale = 1 - (dragPercentage * 0.2)
        opacity = 1 - (dragPercentage * 0.5)
    }
    
    private func handleDragEnded(_ gesture: DragGesture.Value, viewStore: ViewStore<FlashCard.State, FlashCard.Action>) {
        let threshold: CGFloat = 100
        let velocity = gesture.predictedEndTranslation.width - gesture.translation.width
        
        if abs(gesture.translation.width) > threshold || abs(velocity) > 500 {
            if gesture.translation.width > 0 && viewStore.hasPreviousCard {
                withAnimation(.spring()) {
                    offset = UIScreen.main.bounds.width
                    rotation = 10
                    scale = 0.5
                    opacity = 0

                    nextCardScale = 1
                    nextCardOpacity = 1
                } completion: {
                    isRemoving = true
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    viewStore.send(.previousCard)
                    resetCardStateWithAnimation()
                }
            } else if gesture.translation.width < 0 {
                withAnimation(.spring()) {
                    offset = -UIScreen.main.bounds.width
                    rotation = -10
                    scale = 0.5
                    opacity = 0

                    nextCardScale = 1
                    nextCardOpacity = 1
                } completion: {
                    isRemoving = true
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    if viewStore.isLastCard {
                        viewStore.send(.completeCards)
                    } else {
                        viewStore.send(.nextCard)
                    }

                    resetCardStateWithAnimation()
                }
            } else {
                resetCardStateWithAnimation()
            }
        } else {
            resetCardStateWithAnimation()
        }
    }
    
    private func resetCardState() {
        offset = 0
        rotation = 0
        scale = 1
        opacity = 1
        
        isRemoving = false

    }
    
    private func resetCardStateWithAnimation() {
        withAnimation(.spring()) {
            resetCardState()
        }
    }
    
    @ViewBuilder
    private func cardView(for word: Word?, isShowingDefinition: Bool) -> some View {
        if let word = word {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(radius: 10)
                
                VStack(spacing: 20) {
                    Text(word.term)
                        .font(.system(size: 32, weight: .bold))
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    if isShowingDefinition {
                        Divider()
                            .padding(.horizontal)
                        
                        Text(word.definition)
                            .font(.system(size: 24))
                            .multilineTextAlignment(.center)
                            .padding()
                            .transition(.opacity)
                    } else {
                        Text("タップして意味を表示")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.bottom)
                    }
                }
                .padding()
            }
            .frame(height: 300)
            .padding(.horizontal)
        }
    }
}

#Preview {
    NavigationView {
        FlashCardView(
            store: Store(
                initialState: FlashCard.State(
                    words: [
                        Word(term: "Hello", definition: "こんにちは"),
                        Word(term: "World", definition: "世界"),
                        Word(term: "Swift", definition: "素早い、迅速な")
                    ]
                )
            ) {
                FlashCard()
            }
        )
    }
}

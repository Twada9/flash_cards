//
//  DeckDetaiView.swift
//  flash_cards
//
//  Created by wada on 2025/02/16.
//

import SwiftUI
import ComposableArchitecture

struct DeckDetail: Reducer {
    struct State: Equatable {
        var deckId: UUID
        var deckTitle: String // 単語帳のタイトル
        var words: IdentifiedArrayOf<Word> = []
        @PresentationState var editWord: EditWord.State?
        @PresentationState var flashCard: FlashCard.State?
    }
    
    enum Action {
        case onAppear
        case wordsLoaded([Word])
        case addWordButtonTapped
        case editWordButtonTapped(Word)
        case editWord(PresentationAction<EditWord.Action>)
        case saveError
        case deleteWord(IndexSet)
        case flashCardButtonTapped
        case flashCard(PresentationAction<FlashCard.Action>)
    }
    
    @Dependency(\.repositoryClient) private var repositoryClient
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                print("[DeckDetail] Loading words for deck: \(state.deckId)")
                // デッキの単語を読み込む
                return .run { [deckId = state.deckId] send in
                    let words = await repositoryClient.getWords(deckId)
                    print("[DeckDetail] Loaded \(words.count) words")
                    
                    // 重複するIDの単語を除去
                    let uniqueWords = words.reduce(into: [UUID: Word]()) { dict, word in
                        dict[word.id] = word
                    }.values.sorted(by: { $0.term < $1.term })
                    
                    if uniqueWords.count != words.count {
                        print("[DeckDetail] Warning: Removed \(words.count - uniqueWords.count) duplicate words")
                    }
                    
                    await send(.wordsLoaded(uniqueWords))
                }
                
            case let .wordsLoaded(words):
                print("[DeckDetail] Updating state with \(words.count) words")
                state.words = IdentifiedArrayOf(uniqueElements: words)
                return .none
                
            case .addWordButtonTapped:
                state.editWord = EditWord.State(word: Word(term: "", definition: ""))
                return .none
                
            case .editWordButtonTapped(let word):
                state.editWord = EditWord.State(word: word)
                return .none
                
            case .editWord(.presented(.binding(\.$word))):
                // 単語が編集された時の処理
                return .none
                
            case .editWord(.presented(.saveButtonTapped)):
                guard let editWordState = state.editWord,
                      !editWordState.isSaveButtonDisabled else {
                    return .none
                }
                if state.words.contains(where: { $0.id == editWordState.word.id }) {
                    state.words[id: editWordState.word.id] = editWordState.word
                    // 既存の単語を更新
                    return .run { send in
                        do {
                            try await repositoryClient.updateWord(editWordState.word)
                        } catch {
                            print("Error update word: \(error)")
                        }
                    }
                } else {
                    state.words.append(editWordState.word)
                    return .run { [deckId = state.deckId] send in
                        do {
                            try await repositoryClient.addWordToDeck(deckId, editWordState.word)
                        } catch {
                            print("Error saving word: \(error)")
                        }
                    }
                }
                
            case .editWord(.dismiss):
                state.editWord = nil
                return .none
                
            case .saveError:
//                state.words.remove(id: state.editWord.word.id)
                return .none
                
            case .deleteWord(let indexSet):
                // 削除する単語のIDを取得
                let wordIds = indexSet.map { state.words[$0].id }
                
                // ローカルStateから削除
                state.words.remove(atOffsets: indexSet)
                
                // Realmからも削除
                return .run { [deckId = state.deckId] send in
                    for wordId in wordIds {
                        do {
                            try await repositoryClient.removeWordFromDeck(deckId, wordId)
                            try await repositoryClient.deleteWord(wordId)
                        } catch {
                            print("Error deleting word: \(error)")
                        }
                    }
                }
                
            case .flashCardButtonTapped:
                // フラッシュカード画面を表示
                let words = state.words.elements
                state.flashCard = FlashCard.State(words: words)
                return .none
                
            case .flashCard:
                // フラッシュカード関連のアクションを処理
                return .none
                
            default:
                return .none
            }
        }
        .ifLet(\.$editWord, action: /Action.editWord) {
            EditWord()
        }
        .ifLet(\.$flashCard, action: /Action.flashCard) {
            FlashCard()
        }
    }
}

struct DeckDetailView: View {
    let store: StoreOf<DeckDetail>
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            ZStack {
                if viewStore.words.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("単語が登録されていません")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Button {
                            viewStore.send(.addWordButtonTapped)
                        } label: {
                            Label("単語を追加", systemImage: "plus.circle.fill")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                    }
                } else {
                    VStack(spacing: 0) {
                        // 学習ボタン
                        Button {
                            viewStore.send(.flashCardButtonTapped)
                        } label: {
                            HStack {
                                Image(systemName: "play.circle.fill")
                                    .font(.title)
                                Text("学習を始める")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.horizontal)
                            .padding(.top)
                        }
                        
                        // 単語リスト
                        List {
                            ForEach(viewStore.words) { word in
                                Button(action: {
                                    viewStore.send(.editWordButtonTapped(word))
                                }) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(word.term)
                                            .font(.headline)
                                        Text(word.definition)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.vertical, 4)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .onDelete { indexSet in
                                viewStore.send(.deleteWord(indexSet))
                            }
                        }
                        .listStyle(InsetGroupedListStyle())
                    }
                }
            }
            .navigationTitle(viewStore.deckTitle)
            .toolbar {
                if !viewStore.words.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            viewStore.send(.addWordButtonTapped)
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(
                store: self.store.scope(state: \.$editWord, action: DeckDetail.Action.editWord),
                content: { editWordStore in
                    NavigationView {
                        EditWordView(store: editWordStore)
                    }
                }
            )
            .sheet(
                store: self.store.scope(state: \.$flashCard, action: DeckDetail.Action.flashCard),
                content: { flashCardStore in
                    NavigationView {
                        FlashCardView(store: flashCardStore)
                    }
                }
            )
            .onAppear {
                viewStore.send(.onAppear)
            }
        }
    }
}

#Preview {
    NavigationView {
        DeckDetailView(
            store: Store(
                initialState: DeckDetail.State(
                    deckId: UUID(),
                    deckTitle: "Sample Deck",
                    words: [
                        Word(term: "Hello", definition: "こんにちは"),
                        Word(term: "World", definition: "世界")
                    ]
                )
            ) {
                DeckDetail()
            }
        )
    }
}

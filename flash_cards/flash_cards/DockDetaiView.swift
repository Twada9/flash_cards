//
//  DockDetaiView.swift
//  flash_cards
//
//  Created by wada on 2025/02/16.
//

import SwiftUI
import ComposableArchitecture

struct DeckDetail: Reducer {

    struct State: Equatable {
        var deckTitle: String // 単語帳のタイトル
        var words: IdentifiedArrayOf<Word> = []
        @PresentationState var editWord: EditWord.State?
    }

    enum Action {
        case addWordButtonTapped
        case editWordButtonTapped(Word)
        case editWord(PresentationAction<EditWord.Action>)
        case addWord(Word)
        case deleteWord(IndexSet)
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .addWordButtonTapped:
                state.editWord = EditWord.State(word: Word(term: "", definition: ""))
                return .none

            case .editWordButtonTapped(let word):
                state.editWord = EditWord.State(word: word)
                return .none

            case .editWord(.presented(.binding(\.$word))):
                // 単語が編集された時の処理
                return .none

            case .editWord(.dismiss):
                // 単語編集画面が閉じられた時の処理。保存されたかどうかを確認し、必要に応じてリストを更新
                guard let editWordState = state.editWord else { return .none }
                if let index = state.words.firstIndex(where: { $0.id == editWordState.word.id }) {
                    // 既存の単語を更新
                    state.words[id: editWordState.word.id] = editWordState.word
                } else {
                    // 新規単語を追加
                    state.words.append(editWordState.word)
                }
                state.editWord = nil
                return .none

            case .addWord(let word):
                state.words.append(word)
                return .none

            case .deleteWord(let indexSet):
                state.words.remove(atOffsets: indexSet)
                return .none

            default:
                return .none
            }
        }
        .ifLet(\.$editWord, action: /Action.editWord) {
            EditWord()
        }
    }
}

struct DeckDetailView: View {
    let store: StoreOf<DeckDetail>

    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            List {
                ForEach(viewStore.words) { word in
                    HStack {
                        Text(word.term)
                        Spacer()
                        Text(word.definition)
                    }
                    .onTapGesture {
                        viewStore.send(.editWordButtonTapped(word))
                    }
                }
                .onDelete { indexSet in
                    viewStore.send(.deleteWord(indexSet))
                }
            }
            .navigationTitle(viewStore.deckTitle)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewStore.send(.addWordButtonTapped)
                    } label: {
                        Image(systemName: "plus")
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
        }
    }
}

#Preview {
    NavigationView {
        DeckDetailView(
            store: Store(
                initialState: DeckDetail.State(
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

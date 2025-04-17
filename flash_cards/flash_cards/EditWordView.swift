//
//  EditWordView.swift
//  flash_cards
//
//  Created by wada on 2025/02/16.
//

import SwiftUI
import ComposableArchitecture

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

// 単語編集画面の状態
struct EditWord: Reducer {
    struct State: Equatable {
        @BindingState var word: Word
        var isSaveButtonDisabled: Bool {
            word.term.isEmpty || word.definition.isEmpty
        }
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case saveButtonTapped
        case cancelButtonTapped
    }

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
                
            case .saveButtonTapped:
                // 単語が入力されていない場合は保存しない
                if state.isSaveButtonDisabled {
                    return .none
                }
                return .none
                
            case .cancelButtonTapped:
                return .none
            }
        }
    }
}

// 単語帳詳細画面の状態
struct EditWordView: View {
    @Environment(\.dismiss) var dismiss
    let store: StoreOf<EditWord>

    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            Form {
                Section(header: Text("単語")) {
                    TextField("例: Hello", text: viewStore.$word.term)
                        .font(.headline)
                }
                
                Section(header: Text("意味")) {
                    TextEditor(text: viewStore.$word.definition)
                        .font(.headline)
                        .frame(minHeight: 100)
                        .scrollContentBackground(.hidden)
                        .placeholder(when: viewStore.word.definition.isEmpty) {
                            Text("例: こんにちは")
                                .foregroundColor(.gray.opacity(0.7))
                                .font(.headline)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                }
            }
            .navigationTitle(viewStore.word.term.isEmpty ? "新しい単語" : viewStore.word.term)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        viewStore.send(.cancelButtonTapped)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        if !viewStore.isSaveButtonDisabled {
                            viewStore.send(.saveButtonTapped)
                        }
                        dismiss()
                    }
                    .disabled(viewStore.isSaveButtonDisabled)
                }
            }
        }
    }
}

// TextEditorのプレースホルダー拡張
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .topLeading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

#Preview {
    NavigationView {
        EditWordView(
            store: Store(
                initialState: EditWord.State(
                    word: Word(term: "", definition: "")
                )
            ) {
                EditWord()
            }
        )
    }
}

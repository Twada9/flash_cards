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
    let id: UUID = UUID()
    var term: String
    var definition: String
}

// 単語編集画面の状態
struct EditWord: Reducer {
    struct State: Equatable {
        @BindingState var word: Word
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
    }

    var body: some Reducer<State, Action> {
        BindingReducer()
        
//        Reduce { state, action in
//            switch action {
//            case .binding(\.word.definition):
//                return .none
//            case .binding(_):
//                return .none
//            }
//        }
    }
}

// 単語帳詳細画面の状態


struct EditWordView: View {
//    @Perception.Bindable var store: StoreOf<EditWord>
//    @Bindable var store: StoreOf<EditWord>
    @Environment(\.dismiss) var dismiss
    let store: StoreOf<EditWord>

    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            Form {
                TextField("単語", text: viewStore.$word.term)
                TextField("意味", text: viewStore.$word.definition)
            }
            .navigationTitle("単語の編集")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        dismiss()
                    }
                }
            }
        }
    }
}


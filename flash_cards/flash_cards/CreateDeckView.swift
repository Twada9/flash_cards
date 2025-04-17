//
//  CreateDeckView.swift
//  flash_cards
//
//  Created by wada on 2025/02/16.
//

import SwiftUI
import ComposableArchitecture

struct CreateDeck: Reducer {
    struct State: Equatable {
        var title: String = ""
        var description: String = ""
        var isSaveButtonDisabled: Bool {
            title.isEmpty // タイトルが空の場合は保存ボタンを無効にする
        }
    }
    
    enum Action: Equatable {
        case titleChanged(String)
        case descriptionChanged(String)
        case saveButtonTapped
        case cancelButtonTapped
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .titleChanged(let title):
                state.title = title
                return .none
                
            case .descriptionChanged(let description):
                state.description = description
                return .none
                
            case .saveButtonTapped, .cancelButtonTapped:
                return .none
            }
        }
    }
}

struct CreateDeckView: View {
    @Environment(\.dismiss) var dismiss
    let store: StoreOf<CreateDeck>
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            Form {
                Section(header: Text("単語帳情報").font(.headline)) {
                    TextField("タイトル", text: viewStore.binding(
                        get: \.title,
                        send: CreateDeck.Action.titleChanged
                    ))
                    .padding(.vertical, 5)
                    
                    VStack(alignment: .leading) {
                        Text("説明")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        TextEditor(text: viewStore.binding(
                            get: \.description,
                            send: CreateDeck.Action.descriptionChanged
                        ))
                        .frame(height: 100) // 説明欄の高さ
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1) // 枠線を追加
                        )
                    }
                    .padding(.vertical, 5)
                }
                
                Section {
                    Button(action: {
                        viewStore.send(.saveButtonTapped)
                        dismiss()
                    }) {
                        Text("保存")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(viewStore.isSaveButtonDisabled ? Color.gray : Color.blue) // 保存可能/不可能で色を変える
                            .cornerRadius(10)
                    }
                    .disabled(viewStore.isSaveButtonDisabled)
                    .listRowInsets(EdgeInsets()) // ボタンのcontentInsetを削除
                    .padding(.vertical, 5)
                }
                .listRowBackground(Color.clear) // Sectionの背景色を透明にする
            }
            .navigationTitle("新規単語帳")
            .background(Color(.secondarySystemBackground)) // 背景色
            .toolbar { // ツールバーにボタンを追加
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("キャンセル") {
                        viewStore.send(.cancelButtonTapped)
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        CreateDeckView(
            store: Store(initialState: CreateDeck.State()) {
                CreateDeck()
            }
        )
    }
}

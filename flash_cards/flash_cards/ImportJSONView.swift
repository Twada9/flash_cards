//
//  ImportJSONView.swift
//  flash_cards
//
//  JSON import view
//

import SwiftUI
import ComposableArchitecture

struct ImportJSON: Reducer {
    struct State: Equatable {
        @BindingState var jsonText: String = ""
        var isImporting: Bool = false
        var importError: String?
        var importSuccess: Bool = false
        
        var isImportButtonDisabled: Bool {
            jsonText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isImporting
        }
    }
    
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case importButtonTapped
        case importCompleted
        case importFailed(String)
        case cancelButtonTapped
        case dismissAlert
    }
    
    @Dependency(\.repositoryClient) private var repositoryClient
    
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                // エラーをクリア
                if !state.jsonText.isEmpty {
                    state.importError = nil
                }
                return .none
                
            case .importButtonTapped:
                state.isImporting = true
                state.importError = nil
                state.importSuccess = false
                
                let jsonText = state.jsonText
                
                return .run { send in
                    do {
                        // Try to parse as a single deck first
                        do {
                            let deck = try JSONImportService.importDeck(from: jsonText)
                            try await repositoryClient.importDeckFromJSON(deck)
                            await send(.importCompleted)
                            return
                        } catch let singleDeckError {
                            // If single deck parsing fails, try multiple decks
                            do {
                                let decks = try JSONImportService.importDecks(from: jsonText)
                                try await repositoryClient.importDecksFromJSON(decks)
                                await send(.importCompleted)
                                return
                            } catch {
                                // If both fail, report the more helpful error
                                // If the JSON is an array, report the array parsing error, otherwise report single deck error
                                let trimmedJSON = jsonText.trimmingCharacters(in: .whitespacesAndNewlines)
                                if trimmedJSON.hasPrefix("[") {
                                    throw error // Report array parsing error
                                } else {
                                    throw singleDeckError // Report single deck error
                                }
                            }
                        }
                    } catch {
                        await send(.importFailed(error.localizedDescription))
                    }
                }
                
            case .importCompleted:
                state.isImporting = false
                state.importSuccess = true
                state.jsonText = ""
                return .none
                
            case let .importFailed(error):
                state.isImporting = false
                state.importError = error
                return .none
                
            case .cancelButtonTapped:
                return .none
                
            case .dismissAlert:
                state.importError = nil
                state.importSuccess = false
                return .none
            }
        }
    }
}

struct ImportJSONView: View {
    @Environment(\.dismiss) var dismiss
    let store: StoreOf<ImportJSON>
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            VStack(spacing: 0) {
                // ヘッダー説明
                VStack(alignment: .leading, spacing: 8) {
                    Text("JSON形式でデータをインポート")
                        .font(.headline)
                    Text("単語帳と単語をJSON形式で貼り付けてください")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                
                // JSON入力エリア
                TextEditor(text: viewStore.$jsonText)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .overlay(
                        Group {
                            if viewStore.jsonText.isEmpty {
                                VStack {
                                    Text("例:")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text("""
                                        {
                                          "id": "...",
                                          "title": "英単語",
                                          "words": [
                                            {
                                              "id": "...",
                                              "term": "Hello",
                                              "definition": "こんにちは"
                                            }
                                          ]
                                        }
                                        """)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.gray)
                                    .padding()
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .allowsHitTesting(false)
                            }
                        }
                    )
                    .padding(.horizontal)
                
                // インポートボタン
                Button(action: {
                    viewStore.send(.importButtonTapped)
                }) {
                    HStack {
                        if viewStore.isImporting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text(viewStore.isImporting ? "インポート中..." : "インポート")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewStore.isImportButtonDisabled ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(viewStore.isImportButtonDisabled)
                .padding()
            }
            .navigationTitle("JSONインポート")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        viewStore.send(.cancelButtonTapped)
                        dismiss()
                    }
                }
            }
            .alert("エラー", isPresented: .constant(viewStore.importError != nil)) {
                Button("OK") {
                    viewStore.send(.dismissAlert)
                }
            } message: {
                if let error = viewStore.importError {
                    Text(error)
                }
            }
            .alert("成功", isPresented: .constant(viewStore.importSuccess)) {
                Button("OK") {
                    viewStore.send(.dismissAlert)
                    dismiss()
                }
            } message: {
                Text("インポートが完了しました")
            }
        }
    }
}

#Preview {
    NavigationView {
        ImportJSONView(
            store: Store(
                initialState: ImportJSON.State()
            ) {
                ImportJSON()
            }
        )
    }
}

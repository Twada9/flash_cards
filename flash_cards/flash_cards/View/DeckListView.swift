//
//  DeckListView.swift
//  flash_cards
//
//  Created by wada on 2025/02/24.
//

import SwiftUI
import ComposableArchitecture

struct DeckList: Reducer {
    struct State: Equatable {
        var decks: IdentifiedArrayOf<Deck> = []
        @PresentationState var selectedDeck: DeckDetail.State?
        @PresentationState var createDeck: CreateDeck.State?
        @PresentationState var importJSON: ImportJSON.State?
        var hasInitialLoad = false
    }
    
    enum Action {
        case onAppear
        case decksLoaded([Deck])
        case createDeckButtonTapped
        case importJSONButtonTapped
        case deckTapped(Deck)
        case deleteDeck(IndexSet)
        case selectedDeck(PresentationAction<DeckDetail.Action>)
        case createDeck(PresentationAction<CreateDeck.Action>)
        case importJSON(PresentationAction<ImportJSON.Action>)
        case saveDeck(Deck)
    }
    
    @Dependency(\.repositoryClient) private var repositoryClient
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard !state.hasInitialLoad else { return .none }
                state.hasInitialLoad = true
                
                // Realmからデッキリストを読み込む
                return .run { send in
                    let decks = await repositoryClient.getAllDecks()
                    await send(.decksLoaded(decks))
                }
                
            case let .decksLoaded(decks):
                state.decks = IdentifiedArrayOf(uniqueElements: decks)
                return .none
                
            case .createDeckButtonTapped:
                state.createDeck = CreateDeck.State()
                return .none
                
            case .importJSONButtonTapped:
                state.importJSON = ImportJSON.State()
                return .none
                
            case .deckTapped(let deck):
                state.selectedDeck = DeckDetail.State(
                    deckId: deck.id,
                    deckTitle: deck.title,
                    words: []
                )
                return .none
                
            case .deleteDeck(let indexSet):
                // 削除するデッキのIDを取得
                let deckIds = indexSet.map { state.decks[$0].id }
                
                // ローカルStateから削除
                state.decks.remove(atOffsets: indexSet)
                
                // Realmからも削除
                return .run { send in
                    for deckId in deckIds {
                        do {
                            try await repositoryClient.deleteDeck(deckId)
                        } catch {
                            print("Error deleting deck: \(error)")
                        }
                    }
                }
                
            case .selectedDeck(.dismiss):
                state.selectedDeck = nil
                return .none
                
            case .createDeck(.dismiss):
                guard let createDeckState = state.createDeck else { return .none }
                state.createDeck = nil
                
                // キャンセルされた場合は保存しない
                if createDeckState.wasCancelled {
                    return .none
                }
                
                // タイトルが入力されていて、かつキャンセルされていない場合のみ保存
                if !createDeckState.title.isEmpty {
                    let newDeck = Deck(id: UUID(), title: createDeckState.title)
                    return .send(.saveDeck(newDeck))
                }
                return .none
                
            case .importJSON(.dismiss):
                state.importJSON = nil
                // JSONインポート後にデッキリストを再読み込み
                return .run { send in
                    let decks = await repositoryClient.getAllDecks()
                    await send(.decksLoaded(decks))
                }
                
            case .saveDeck(let deck):
                // すでに存在するかチェック
                if state.decks[id: deck.id] == nil {
                    state.decks.append(deck)
                } else {
                    state.decks[id: deck.id] = deck
                }
                
                // Realmに保存
                return .run { send in
                    do {
                        try await repositoryClient.saveDeck(deck)
                    } catch {
                        print("Error saving deck: \(error)")
                    }
                }
                
            default:
                return .none
            }
        }
        .ifLet(\.$selectedDeck, action: /Action.selectedDeck) {
            DeckDetail()
        }
        .ifLet(\.$createDeck, action: /Action.createDeck) {
            CreateDeck()
        }
        .ifLet(\.$importJSON, action: /Action.importJSON) {
            ImportJSON()
        }
    }
}

struct DeckListView: View {
    let store: StoreOf<DeckList>
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            NavigationView {
                ZStack {
                    if viewStore.decks.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "square.stack.3d.up")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("単語帳がありません")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            VStack(spacing: 12) {
                                Button {
                                    viewStore.send(.createDeckButtonTapped)
                                } label: {
                                    Label("新しい単語帳を作成", systemImage: "plus.circle.fill")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.blue)
                                        .cornerRadius(10)
                                }
                                
                                Button {
                                    viewStore.send(.importJSONButtonTapped)
                                } label: {
                                    Label("JSONをインポート", systemImage: "square.and.arrow.down")
                                        .font(.headline)
                                        .foregroundColor(.blue)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(10)
                                }
                            }
                            .padding(.horizontal, 40)
                        }
                    } else {
                        List {
                            ForEach(viewStore.decks) { deck in
                                Button(action: {
                                    viewStore.send(.deckTapped(deck))
                                }) {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(deck.title)
                                                .font(.headline)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray)
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .onDelete { indexSet in
                                viewStore.send(.deleteDeck(indexSet))
                            }
                        }
                        .listStyle(InsetGroupedListStyle())
                    }
                }
                .navigationTitle("単語帳")
                .toolbar {
                    if !viewStore.decks.isEmpty {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Menu {
                                Button {
                                    viewStore.send(.createDeckButtonTapped)
                                } label: {
                                    Label("新しい単語帳", systemImage: "plus")
                                }
                                Button {
                                    viewStore.send(.importJSONButtonTapped)
                                } label: {
                                    Label("JSONをインポート", systemImage: "square.and.arrow.down")
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                            }
                        }
                    }
                }
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .sheet(
                store: self.store.scope(state: \.$selectedDeck, action: DeckList.Action.selectedDeck),
                content: { selectedDeckStore in
                    NavigationView {
                        DeckDetailView(store: selectedDeckStore)
                    }
                }
            )
            .sheet(
                store: self.store.scope(state: \.$createDeck, action: DeckList.Action.createDeck),
                content: { createDeckStore in
                    NavigationView {
                        CreateDeckView(store: createDeckStore)
                    }
                }
            )
            .sheet(
                store: self.store.scope(state: \.$importJSON, action: DeckList.Action.importJSON),
                content: { importJSONStore in
                    NavigationView {
                        ImportJSONView(store: importJSONStore)
                    }
                }
            )
        }
    }
}

#Preview {
    DeckListView(
        store: Store(
            initialState: DeckList.State(
                decks: [
                    Deck(id: UUID(), title: "英語"),
                    Deck(id: UUID(), title: "数学")
                ]
            )
        ) {
            DeckList()
        }
    )
}

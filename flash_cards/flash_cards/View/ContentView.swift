import SwiftUI
import ComposableArchitecture

struct Content: Reducer {
    struct State: Equatable {
        var deckList = DeckList.State()
        var isLoading = false
    }

    enum Action {
        case deckList(DeckList.Action)
        case appStart
        case didFinishInitialization
    }

    @Dependency(\.repositoryClient) private var repositoryClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .appStart:
                guard !state.isLoading else { return .none }
                state.isLoading = true
                
                return .run { send in
                    do {
                        try await DemoData.insertDemoDataIfNeeded()
                    } catch {
                        print("[Content] Failed to insert demo data: \(error)")
                    }
                    await send(.didFinishInitialization)
                }
                
            case .didFinishInitialization:
                state.isLoading = false
                return .send(.deckList(.onAppear))
                
            case .deckList:
                return .none
            }
        }
        Scope(state: \.deckList, action: /Action.deckList) {
            DeckList()
        }
    }
}

struct ContentView: View {
    let store: StoreOf<Content>

    var body: some View {
        DeckListView(
            store: self.store.scope(
                state: \.deckList,
                action: Content.Action.deckList
            )
        )
        .onAppear {
            store.send(.appStart)
        }
    }
}

#Preview {
    ContentView(
        store: Store(initialState: Content.State()) {
            Content()
        }
    )
}

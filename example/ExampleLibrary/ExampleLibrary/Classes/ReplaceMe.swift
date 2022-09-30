import ComposableArchitecture

func stuff() {
    let _ = Store<Void, Void>(
        initialState: (),
        reducer: Reducer({state, _, _ in .none}),
        environment: ()
    )
}

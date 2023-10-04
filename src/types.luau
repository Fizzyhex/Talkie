--!strict

export type Resolve<T...> = (T...) -> ()
export type Reject<T...> = Resolve<T...>

export type ClientEventSend<T...> = {
    send: (self: any, T...) -> ()
}

export type ClientEventReceive<T...> = {
    subscribe: (
        self: any,
        cleanupTable: { [any]: any },
        callback: (T...) -> (),
        filter: ((T...) -> any)?
    ) -> (),
    subscribeOnce: (
        self: any,
        cleanupTable: { [any]: any },
        callback: (T...) -> (),
        filter: ((T...) -> any)?
    ) -> (),
}

export type ClientEvent<ClientEventSend, ClientEventReceive> = ClientEventSend & ClientEventReceive
export type ServerEvent<T...> = {
    subscribe: (
        self: any,
        cleanupTable: { [any]: any },
        callback: (...any) -> (),
        filter: ((...any) -> any)?
    ) -> (),
    subscribeOnce: (
        self: any,
        cleanupTable: { [any]: any },
        callback: (...any) -> (),
        filter: ((...any) -> any)?
    ) -> (),

    sendToAll: (self: any, T...) -> (),
    sendToPlayer: (self: any, playerOrPlayers: Player | { [any]: Player }, T...) -> (),
    sendToAllExcept: (self: any, player: Player, T...) -> (),
    sendFilter: (self: any, filter: ((player: Player, T...) -> boolean), T...) -> (),
} 

export type ClientDelegate<T...=...any> = {
    setCallback: (
        self: any,
        cleanupTable: { [any]: any },
        callback: (resolve: Resolve<...any>, reject: Reject<...any>) -> (...any) -> ()
    ) -> (),

    subscribe: (
        self: any,
        cleanupTable: { [any]: any },
        callback: (T...) -> (),
        filter: ((T...) -> any)?
    ) -> (),
    subscribeOnce: (
        self: any,
        cleanupTable: { [any]: any },
        callback: (T...) -> (),
        filter: ((T...) -> any)?
    ) -> (),
}

export type ServerDelegate = {
    setCallback: (
        self: any,
        cleanupTable: { [any]: any },
        callback: (resolve: Resolve<...any>, reject: Reject<...any>) -> (...any) -> ()
    ) -> (),
    subscribe: (
        self: any,
        cleanupTable: { [any]: any },
        callback: (...any) -> (),
        filter: ((...any) -> any)?
    ) -> (),
    subscribeOnce: (
        self: any,
        cleanupTable: { [any]: any },
        callback: (...any) -> (),
        filter: ((...any) -> any)?
    ) -> (),
}

return nil
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Promise = require(ReplicatedStorage.Packages.Promise)

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
    expect: (
        self: any,
        cleanupTable: { [any]: any },
        filter: ((T...) -> boolean)?
    ) -> Promise.TypedPromise<T...>,
    expectFrom: (
        self: any,
        cleanupTable: { [any]: any },
        player: Player,
        filter: ((T...) -> boolean)?
    ) -> Promise.TypedPromise<T...>,
}

-- https://github.com/Roblox/luau/pull/86
export type TypedClientEvent<ClientEventSend, ClientEventReceive> = ClientEventSend & ClientEventReceive
export type ClientEvent = ClientEventSend<...any> & ClientEventReceive<...any>

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

    expect: (
        self: any,
        cleanupTable: { [any]: any },
        filter: ((player: Player, ...any) -> boolean)?
    ) -> Promise.TypedPromise<...any>,
    expectFrom: (
        self: any,
        cleanupTable: { [any]: any },
        player: Player,
        filter: ((player: Player, ...any) -> boolean)?
    ) -> Promise.TypedPromise<...any>,
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
        callback: (resolve: Resolve<...any>, reject: Reject<...any>) -> (player: Player, ...any) -> ()
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
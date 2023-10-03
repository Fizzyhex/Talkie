--!strict
local Promise = require(script.Parent.Parent.Promise)

export type Resolve<T...> = (T...) -> ()
export type Reject<T...> = Resolve<T...>

export type ServerChannelSend<T...=...any> = {
    sendToAll: (self: ServerChannelSend<T...>, T...) -> (),
    sendToClient: (self: ServerChannelSend<T...>, Player | { [any]: Player }, T...) -> (),
    sendToAllExcept: (self: ServerChannelSend<T...>, Player, T...) -> (),
    sendWithFilter: (self: ServerChannelSend<T...>, ((Player) -> (any)), T...) -> (),

    subscribe: (
        self: ServerChannelSend<T...>, 
        cleanupTable: { [any]: any },
        callback: (...unknown) -> ()
    ) -> (() -> ()),
}

export type ServerChannelReceive<Resolver=(...any) -> (), Rejecter=(...any) -> ()> = {
    setTicketHandler: (
        self: ServerChannelReceive<Resolver, Rejecter>,
        cleanupTable: {},
        callback: (resolve: Resolver, reject: Rejecter) -> ((...unknown) -> ())
    ) -> (), 
}

export type ServerChannel<serverChannelSend, serverChannelReceive> = {
    type: "channel",
    identifier: string,

    waitForDataFrom: (
        self: ServerChannelSend<serverChannelSend, serverChannelReceive>,
        Player,
        ((Player, ...unknown) -> (any))?
    ) -> Promise.TypedPromise<(Player, ...unknown)>,

    waitForData: (
        self: ServerChannelSend<serverChannelSend, serverChannelReceive>,
        ((Player, ...unknown) -> (any))?
    ) -> Promise.TypedPromise<(Player, ...unknown)>,
} & serverChannelSend & serverChannelReceive

export type ClientChannelSend<T...=...any> = {
    send: (self: ClientChannel, T...) -> (),
    openTicket: (self: ClientChannel, T...) -> Promise.Promise,
}

-- TODO: Type sending and receiving tickets from the client.
-- It's likely to require 2 unique types, unlike the server.

export type ClientChannelReceive<Resolver=(...any) -> (), Rejecter=(...any) -> (), T...=...any> = {
    waitForData: (self: ClientChannel, T...) -> (),
    openTicket: (self: ClientChannel, T...) -> Promise.Promise,
}

export type ClientChannel<Send=nil, Receive=nil> = {
    type: "channel",
    identifier: string,
} & Send & Receive

return nil
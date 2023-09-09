local Promise = require(script.Parent.Packages.Promise)

export type ServerChannel<T...=...any> = {
    type: "channel",
    identifier: string,

    sendToAll: (self: ServerChannel<T...>, T...) -> (),
    sendTo: (self: ServerChannel<T...>, Player | { [any]: Player }, T...) -> (),
    sendToAllExcept: (self: ServerChannel<T...>, Player, T...) -> (),
    sendFilter: (self: ServerChannel<T...>, ((Player) -> (any)), T...) -> (),

    expectFrom: (self: ServerChannel<T...>, Player, ((Player, ...unknown) -> (any))?) -> Promise.TypedPromise<(Player, ...unknown)>,
    expect: (self: ServerChannel<T...>, ((Player, ...unknown) -> (any))?) -> Promise.TypedPromise<(Player, ...unknown)>,

    subscribe: (self: ServerChannel<T...>, cleanupTable: { [any]: any }, callback: (...unknown) -> ()) -> (() -> ()),
}

export type ClientChannelSend<T...=...any> = {
    send: (self: ClientChannel, T...) -> (),
}

export type ClientChannelExpect<T...=...any> = {
    expect: (self: ClientChannel, T...) -> (),
}

export type ClientChannel<Send=nil, Expect=nil> = {
    type: "channel",
    identifier: string
} & Send & Expect

return nil
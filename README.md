# Talkie


> ⚠ This library is a work in progress! It's API surface may change significantly with updates and their may be bugs. Use at your own risk!

[View on Wally](https://wally.run/package/fizzyhex/talkie?version=0.1.0)

Talkie is an experimental networking library for Roblox.

## Key features

- 🏃 Bandwidth efficient - Have absurd amounts of remotes without any extra cost!
- ♻ Lightweight
- 🗒 Luau typings
- 😁 Super friendly API surface
- 🧑‍💻 Greatly extendable - pass your own filters!
- 🟣 Integration with [Promises](https://github.com/lukadev-0/rbx-typed-promise)

## Samples

### Chat Event

```lua
-- Client

local Talkie = require(somewhere.Talkie)
local ClientEvent = Talkie.ClientEvent

local messageEvent: Talkie.ClientEvent<string> = ClientEvent("send_message")

messageEvent:send("Hello world!")
```

```lua
-- Server

local Talkie = require(somewhere.Talkie)
local ServerEvent = Talkie.ServerEvent
local TypeGuard = Talkie.TypeGuard

local messageEvent: Talkie.ServerEvent = ServerEvent("send_message")

messageEvent:subscribe(
    function(player, message)
        print(`[{player}]: {message}`)
    end,
    -- This utility will handle sanity checks for us!
    TypeGuard.new(TypeGuard.Any(), "string")
)
```

### Spawn Character on Load

```lua
-- Client

local ContentProvider = game:GetService("ContentProvider")

local Talkie = require(somewhere.Talkie)
local ClientEvent = Talkie.ClientEvent

local loadEvent = ClientEvent("load_confirmation")

ContentProvider:PreloadAsync("rbxassetid://00000000", ...)
-- Tell the server we've loaded in
loadEvent:send()
```

```lua
-- Server

local Players = game:GetService("Players")

local Talkie = require(somewhere.Talkie)
local ServerEvent = Talkie.ServerEvent

local loadEvent = ServerEvent("load_confirmation")

local function onPlayerAdded(player: Player)
    loadEvent
        :expectFrom(player)
        :andThen(function()
            player:LoadCharacter()
        end)
        :timeout(30, "Timed out") -- Prevent the player from hanging the event forever!
        :catch(warn)
end

Players.PlayerAdded:Connect(onPlayerAdded)

for _, player in Players:GetPlayers() do
    onPlayerAdded(player)
end
```
# YSMM

Y: Yami
S: Shio
M: Modding
M: Module

A incredibly simple wrapper for vLuau that allows secure calling of luau code with function blacklisting and custom global support.

## Usage

```lua
local YSMM = require(game:GetService("ReplicatedStorage"):WaitForChild("YSMM"))
local function coolFunction()
    print("coolFunction called")
end

YSMM.sandbox([[
coolFunction() -- this will work because we added it to the env
print("hey!")
local a = Instance.new("Part") --will error because of the sandbox, unless you add Instance to the env
print(a)
]], {
        coolFunction = coolFunction,
        print = print,
        math = math,
        string = string,
        table = table,
        coroutine = coroutine,
        os = os,
        task = task,
        --Instance = Instance, --uncomment this to allow Instance creation in the sandbox
    })()

```

alternatively, you can use the `YSMM:load` although its deprecated and pretty unsafe.

```lua
local YSMM = require(game:GetService("ReplicatedStorage"):WaitForChild("YSMM"))
local function coolFunction()
    print("coolFunction called")
end
local function blacklistedFunction()
    warn("blacklistedFunction called")
end

YSMM:load([[
    xpcall(function() --xp calling will mess up debugging lines because of weird luau magic, so only use it if you know how to debug properly
        local rep = game:GetService("ReplicatedStorage")
        print(rep)
    end, function(err)
        print(err)
    end)
    print("hello from YSMM!")
    coolFunction()
    local instance = Instance.new("Part", workspace)
    blacklistedFunction()
]], 
    {
        coolFunction = coolFunction,
        blacklistedFunction = blacklistedFunction, -- this will be blacklisted and not callable from the script
    },
    {
        ["Services"] = {
            ["Players"] = true,
            ["ReplicatedStorage"] = true,
        },
        ["Functions"] = {
            blacklistedFunction = true
        },
    }, false)() --YSMM:load returns a function that you can call to execute the code, that means instead of just calling it, you can also store it in a variable and call it later (or use it with coros / task)

--[[
    Cannot access blacklisted service: ReplicatedStorage
    hello from YSMM!
    coolFunction called
    Cannot access blacklisted function: blacklistedFunction()
]]
```

## API

### `YSMM.sandbox(code: string, globals: table): function`

Creates a sandboxed environment for the code with no access to the DataModel or normal roblox globals.

- `code`: The code to execute. (String)
- `globals`: A table of globals to add to the environment. (Table(Function))
- Returns a function that can be called to execute the code.

### `YSMM.raw(code: string, globals: table): function`

Unsafe version of `YSMM:load` that does not block any globals or services. Use at your own risk.
Note: it also adds itself (loadstring) to the genv, allowing for infinitely recursive loadstring calls.

- `code`: The code to execute. (String)
- `globals`: A table of globals to add to the environment. (Table(Function))
- Returns a function that can be called to execute the code.

---

### Deprecated

#### `YSMM:load(code: string, globals: table, blacklisted: table, shouldBlockDataModelAccess: boolean): function`

Loads the code and returns a function that can be called to execute the code.

- `code`: The code to execute. (String)
- `globals`: A table of globals to add to the environment. (Table(Function))
- `blacklisted`: A table of blacklisted globals. (Table(Boolean))
- `shouldBlockDataModelAccess`: A boolean that determines if the script should be able to access the DataModel. (Boolean)
- Returns a function that can be called to execute the code.


## YGENV

YGENV (yami global env) is a module that provides helper global functions for YSMM. It is NOT automatically included in the environment, so you have to add it manually.

### Usage

```lua
local YSMM = require(game:GetService("ReplicatedStorage"):WaitForChild("YSMM"))
local YGENV = require(game:GetService("ReplicatedStorage"):WaitForChild("YGENV"))

local genv = {
    print = print,
}

for k, v in pairs(YGENV) do
    genv[k] = v -- add all the YGENV functions to the environment
end

YSMM.sandbox([[
    print(compress("hello world")) -- compresses the string using buffer
]], genv)()
```

### Functions

- `compress(data: string): string` - Compresses the data using buffer.
- `decompress(data: string): string` - Decompresses the data using buffer.
- `HttpGetAsync(url: string, headers: table): string` - Makes an async HTTP GET request to the url with the given headers. (**MUST BE INITALIZED WITH AN EXTERNAL SCRIPT FOR SECURITY REASONS**)
- `HttpPostAsync(url: string, data: string, headers: table): string` - Makes an async HTTP POST request to the url with the given data and headers. (**MUST BE INITALIZED WITH AN EXTERNAL SCRIPT FOR SECURITY REASONS**)
- `getgenv(): table` - Returns the global environment. (technically its not an actual genv, but its a table that is used to store the globals for the script so who cares)
- `merge(t1: table, t2: table): table` - Merges the two tables and returns the merged table.
- `uuid(): string` - Returns a random UUIDv4 string.

### Tips

- Because the sandbox is only really just removing globals and datamodel related stuff, its still technically possible to traverse if an instance is passed by using .Parent (this doesnt work on :load because of the blacklisting) but this can easily be fixed by just prefixing whatever code your running with a `setfenv(setmetatable({}, {__index = function() return nil end}))` or something similar to that which hooks whatever stuff you dont want. (this is not done by default because it would break a lot of stuff and make it harder to use)

- If you want 100% secure code follow the above and only pass your own genv to the sandbox with stuff you want the modding framework to access, e.g instead of instance.new you could just have CreateWeapon() or something like that passed to the genv, this means that only code you've actually written can execute stuff outside of the sandbox.

## Credits

- [vLuau](https://github.com/kosuke14/vLuau) - The original project that this is based on.
- [Fiu](https://github.com/TheGreatSageEqualToHeaven/Fiu) - Luau Bytecode Interpreter that vLuau uses.
- [LuauCeption](https://github.com/RadiatedExodus/LuauCeption) - Running Luau in Luau.

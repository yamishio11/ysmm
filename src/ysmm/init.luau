local YSMM = {}

-- |G| Global Variables

local Modules = script.Modules
local vluau = require(Modules.vLuau)

-- |F| Functions


local function interceptService(serviceName)
	local service = game:GetService(serviceName)
	if service == nil then
		return error("Cannot access non-existent service: " .. serviceName, 0)
	else
		return service
	end
end

function YSMM:load(source, globals, blacklist, shouldBlockDataModelAccess)
	local fenv = getfenv(debug.info(2, 'f'))
	local blacklistedServices = blacklist["Services"] or {}
	local blacklistedFunctions = blacklist["Functions"] or {}
    local env = setmetatable({}, { --basic security measures, service blacklist is probably possible to bypass but thanks to my awful code 90% of the time it spams random errors
        __index = function(self, k)
			if k == "workspace" then
				if shouldBlockDataModelAccess then
					return error("DataModel access is restricted", 0)
				end
			end
            if k == "game" then
				if shouldBlockDataModelAccess then
					return error("DataModel access is restricted", 0)
				end
                return setmetatable({}, {
                    __index = function(_, cname)
						if blacklistedServices[cname] then
							return error("Cannot access blacklisted service: " .. cname, 0)
						end
						if cname == "GetService" or "FindService" then
							return function(_, serviceName)
								if blacklistedServices[serviceName] then
									return error("Cannot access blacklisted service: " .. serviceName, 0)
								end
								return interceptService(serviceName)
							end
						end
						return error("DataModel access is restricted: " .. cname, 0)
					end,
					__newindex = function(_, k, v)
						if blacklistedServices[k] then
							return error("Cannot set blacklisted service: " .. k, 0) --in testing some stuff tried to mess with this, just fixing it
						else
							rawset(self, k, v)
						end
                    end,
					__tostring = function()
						return "game" --because of more weird luau errors
					end,
					__metatable = false --cause you could just get the metatable and get the game object
                })
            end
            if blacklistedFunctions[k] then
                return error("Cannot access blacklisted function: " .. k, 0)
            end
            if globals[k] then
                return globals[k]
            end
            if fenv[k] then
                return fenv[k]
            end
            return error("Cannot access non-existent function: " .. k, 0)
        end,
		__newindex = function(self, k, v)
			if blacklistedFunctions[k] then
				return error("Cannot set blacklisted function: " .. k, 0)
			else
				rawset(self, k, v)
			end
		end,
    })

	local bytecode, _ = vluau.luau_compile(source)
	if bytecode:sub(1, 1) ~= "\0" then
		return vluau.luau_load(bytecode, env)
	else
		return error((globals or '@') .. bytecode:sub(2), 0)
	end
end

function YSMM.sandbox(source, globals)
    local env = {}
    for k, v in pairs(globals) do
		env[k] = v
    end
    setmetatable(env, {
        __index = function(self, k)
			if globals[k] then
				return globals[k]
			end
            return nil
        end,
        __newindex = function(self, k, v)
			if globals[k] then
				return error("Cannot set secured function: " .. k, 0)
			else
				rawset(self, k, v)
			end
        end,
    })
    local bytecode, _ = vluau.luau_compile(source)
    if bytecode:sub(1, 1) ~= "\0" then
        return vluau.luau_load(bytecode, env)
    else
        return error((globals or '@') .. bytecode:sub(2), 0)
    end
end

function YSMM.raw(source, globals)
	if not globals then
		globals = {}
	end
	local fenv = getfenv(debug.info(2, 'f'))
	globals.loadstring = function(str)
		YSMM.raw(str, globals)()
	end
	local env = setmetatable({}, {
		__index = function(self, k)
			if globals[k] then
				return globals[k]
			end
			if fenv[k] then
				return fenv[k]
			end
			return nil
		end,
		__newindex = function(self, k, v)
			if globals[k] then
				return error("Cannot set secured function: " .. k, 0)
			else
				rawset(self, k, v)
			end
		end,
	})
	local bytecode, _ = vluau.luau_compile(source)
	if bytecode:sub(1, 1) ~= "\0" then
		return vluau.luau_load(bytecode, env)
	else
		return error((globals or '@') .. bytecode:sub(2), 0)
	end
end


-- |R| Return

return YSMM
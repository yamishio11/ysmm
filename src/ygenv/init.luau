--YGENV: Yami Global Environment
--[[
Provides helpers functions for various stuff
--]]

local YGENV = {}
local HttpService = game:GetService("HttpService");
local buffer_tostring = buffer.tostring;
local buffer_fromstring = buffer.fromstring;

function YGENV.compress(text : string) : string  -- yes, this is the same compression as rizzcat
	local mode = "split";
	if #text < 1000000 then
		mode = "single";
	else
		mode = "split";
	end
	if mode == "split" then
		local chunks = {};
		local chunk_size = 1000000;
		for i = 1, #text, chunk_size do
			table.insert(chunks, HttpService:JSONEncode(buffer_fromstring(text:sub(i, i + chunk_size - 1))));
		end
		return table.concat(chunks, "__VVS__");
	else
		return HttpService:JSONEncode(buffer_fromstring(text));
	end
end

function YGENV.decompress(text : string) : string
	local mode = "split";
	if text:find("__VVS__") == nil then
		mode = "single";
	else
		mode = "split";
	end
	if mode == "split" then
		local chunks = text:split("__VVS__");
		local decoded_chunks = {};
		for i, chunk in ipairs(chunks) do
			decoded_chunks[i] = buffer_tostring(HttpService:JSONDecode(chunk));
		end
		return table.concat(decoded_chunks);
	else
		return buffer_tostring(HttpService:JSONDecode(text));
	end
end

function YGENV.HttpGetAsync(url : string, headers : table?) : string
    local remote = game.ReplicatedStorage:WaitForChild("YGENVHttpService")
    local response = remote:InvokeServer("HttpGetAsync", url)
    if response then
        return response
    else
        error("Failed to get response from server")
    end
end

function YGENV.HttpPostAsync(url : string, data : table?) : string
    local remote = game.ReplicatedStorage:WaitForChild("YGENVHttpService")
    local response = remote:InvokeServer("HttpPostAsync", url, data)
    if response then
        return response
    else
        error("Failed to get response from server")
    end
end

function YGENV.getgenv()
    return getfenv(debug.info(2, 'f'))
end

function YGENV.merge(t1 : table, t2 : table) : table
    local merged = {}
    for k, v in pairs(t1) do
        merged[k] = v
    end
    for k, v in pairs(t2) do
        merged[k] = v
    end
    return merged
end

function YGENV.uuid()
    local uuid = HttpService:GenerateGUID(false)
    uuid = uuid:gsub("-", "")
    uuid = uuid:sub(1, 8) .. "-" .. uuid:sub(9, 12) .. "-" .. uuid:sub(13, 16) .. "-" .. uuid:sub(17, 20) .. "-" .. uuid:sub(21, 32)
    return uuid --actually uuid4 compliant
end


local export = {}
for k, v in pairs(YGENV) do
    if type(v) == "function" then
        export[k] = v
    end
end
return export
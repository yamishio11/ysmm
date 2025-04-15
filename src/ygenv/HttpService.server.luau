local remote = Instance.new("RemoteFunction")
remote.Name = "YGENVHttpService"
remote.Parent = game.ReplicatedStorage
remote.OnServerInvoke = function(player, method, url, data)
    if method == "HttpGetAsync" then
        return game.HttpService:GetAsync(url, data)
    elseif method == "HttpPostAsync" then
        return game.HttpService:PostAsync(url, data);
    end
end
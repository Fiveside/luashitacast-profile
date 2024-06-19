local ServiceManager = {};
ServiceManager.__index = ServiceManager;



function ServiceManager:new()
    local obj = {};
    setmetatable(obj, self);
    obj.services = T{};
    return obj;
end

function ServiceManager:register(name, service)
    if self.services[name] == nil then
        self.services[name] = service;
    else
        error("A service has already been registered with the name " .. name, 2);
    end
end

function ServiceManager:request(name)
    return self.services[name];
end

function ServiceManager:destroy()
    for i = #self.services, 1, -1 do
        if self.services[i].destroy ~= nil then
            self.services[i]:destroy()
        end
    end
end

return ServiceManager;
local ServiceManager = require('services/service_manager');

local Export = {};

Export.createServiceManager = function ()
    return ServiceManager:new();
end
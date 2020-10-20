local BasePlugin = require "kong.plugins.base_plugin"
local access = require "kong.plugins.jwt-plus.main"

local PEPPlugin = BasePlugin:extend()

function PEPPlugin:new()
	PEPPlugin.super.new(self, "jwt-plus")
end

function PEPPlugin:access(conf)
	PEPPlugin.super.access(self)

	local ok, err = access.run(conf)	
	if not ok then
      return kong.response.exit(err.status, err.errors or { message = err.message })
    end
end

return PEPPlugin
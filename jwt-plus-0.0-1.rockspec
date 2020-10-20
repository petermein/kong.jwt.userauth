
package = "jwt-plus"
version = "0.0-1"

local pluginName = "jwt-plus"

source = {
  url = "https://infratron.io"
}
description = {
  summary = "A Kong plugin, that extract ifno from a JWT token and add this to the header",
  license = "Private"
}
dependencies = {
  "lua ~> 5.1",
  "json4lua ~> 0.9.30-1"
}
build = {
  type = "builtin",
  modules = {
    ["kong.plugins."..pluginName..".main"] = "kong/plugins/"..pluginName.."/main.lua",
    ["kong.plugins."..pluginName..".handler"] = "kong/plugins/"..pluginName.."/handler.lua",
    ["kong.plugins."..pluginName..".schema"] = "kong/plugins/"..pluginName.."/schema.lua",
    ["kong.plugins."..pluginName..".utils"] = "kong/plugins/"..pluginName.."/utils.lua",
    ["kong.plugins."..pluginName..".jwt_parser"] = "kong/plugins/"..pluginName.."/jwt_parser.lua"
  }
}

-- Imports
package.path = package.path .. ";../?.lua"
local lua_module = require("lua_module")

function main()
  local smartObjectT = lua_module.getSmartObjectsTable()
  print(#smartObjectT)
end

main()
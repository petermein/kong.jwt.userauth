local utils_module = {}

-- a simple log function
-- TODO: use a real log module
function utils_module.printToFile(line, txt)
	local s = "echo \"Linha " .. line .. " - " .. txt .."\"  >> /tmp/lualogs.txt"
	os.execute(s)
end

-- String split (or explode)
function utils_module.split(source, delimiters)
      local elements = {}
      local pattern = '([^'..delimiters..']+)'
      string.gsub(source, pattern, function(value) elements[#elements + 1] =     value;  end);
      return elements
end

function utils_module.dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

function utils_module.get_key_for_value( t, value )
  for k,v in pairs(t) do
    if v==value then return k end
  end
  return nil
end

return utils_module


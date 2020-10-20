local _M = {}
local pl_stringx = require "pl.stringx"
local req_get_headers = ngx.req.get_headers
local http = require "socket.http"

local utils = require "kong.plugins.jwt-plus.utils"
local constants = require "kong.constants"
local jwt_decoder = require "kong.plugins.jwt-plus.jwt_parser"

local fmt = string.format
local kong = kong
local type = type
local error = error
local ipairs = ipairs
local tostring = tostring
local re_gmatch = ngx.re.gmatch


local function retrieve_token(conf)
  local args = kong.request.get_query()
  for _, v in ipairs(conf.uri_param_names) do
    if args[v] then
      return args[v]
    end
  end

  local var = ngx.var
  for _, v in ipairs(conf.cookie_names) do
    local cookie = var["cookie_" .. v]
    if cookie and cookie ~= "" then
      return cookie
    end
  end

  local request_headers = kong.request.get_headers()
  for _, v in ipairs(conf.header_names) do
    local token_header = request_headers[v]
    if token_header then
      if type(token_header) == "table" then
        token_header = token_header[1]
      end
      local iterator, iter_err = re_gmatch(token_header, "\\s*[Bb]earer\\s+(.+)")
      if not iterator then
        kong.log.err(iter_err)
        break
      end

      local m, err = iterator()
      if err then
        kong.log.err(err)
        break
      end

      if m and #m > 0 then
        return m[1]
      end
    end
  end
end

function _M.run(conf)
    -- missing JWT token on the HTTP header
    -- if not req_get_headers()["Authorization"] then
    --   return kong.response.exit(401)
    -- end

    ngx.log(ngx.STDERR, 'Request!')


    local token, err = retrieve_token(conf)
      if err then
        return error(err)
      end

    local token_type = type(token)
    if token_type ~= "string" then
      if token_type == "nil" then
        return false, { status = 401, message = "Unauthorized" }
      elseif token_type == "table" then
        return false, { status = 401, message = "Multiple tokens provided" }
      else
        return false, { status = 401, message = "Unrecognizable token" }
      end
    end

    -- Decode token to find out who the consumer is
    local jwt, err = jwt_decoder:new(token)
    if err then
      return false, { status = 401, message = "Bad token; " .. tostring(err) }
    end

    local claims = jwt.claims
    local header = jwt.header

    -- Retrieve the secret
    local algorithm = conf.algorithm or "RS256"
    local public_key = conf.public_key or "public_key"
    local private_key = conf.private_key or "private_key"

    -- Verify "alg"
    if jwt.header.alg ~= algorithm then
      return false, { status = 401, message = "Invalid algorithm" }
    end

    local jwt_secret_value = algorithm ~= nil and algorithm:sub(1, 2) == "HS" and
                            private_key or public_key

    ngx.log(ngx.STDERR, jwt_secret_value)

    if conf.secret_is_base64 then
      jwt_secret_value = jwt:base64_decode(jwt_secret_value)
    end

    if not jwt_secret_value then
      return false, { status = 401, message = "Invalid key/secret" }
    end

    -- Now verify the JWT signature
    if not jwt:verify_signature(jwt_secret_value) then
      return false, { status = 401, message = "Invalid signature" }
    end

    if err then
      return error(err)
    end


    -- Verify the JWT registered claims
    local ok_claims, errors = jwt:verify_registered_claims(conf.claims_to_verify)
    if not ok_claims then
      return false, { status = 401, errors = errors }
    end

    -- Verify the JWT registered claims
    if conf.maximum_expiration ~= nil and conf.maximum_expiration > 0 then
      local ok, errors = jwt:check_maximum_expiration(conf.maximum_expiration)
      if not ok then
        return false, { status = 401, errors = errors }
      end
    end

    -- Validate scopes
    local ok_claims, errors = jwt:verify_scopes(conf.scopes_to_validate, conf.scope_claim)
    if not ok_claims then
      return false, { status = 401, errors = errors }
    end

    local set_header = kong.service.request.set_header


    -- Promote fields to headers
    for name, value in pairs(claims) do

      local header_prefix = conf.header_prefix or "jwt";

      name = header_prefix .. "-" .. name

      if type(value) == 'table' then
        value = table.concat(value, ",")
      end

      set_header(name, value)
    end

    local set_header = kong.service.request.set_header

  
    

    return true
end





return _M

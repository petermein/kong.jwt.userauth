local typedefs = require "kong.db.schema.typedefs"

return {
  name = "jwt-plus",
  fields = {
    { protocols = typedefs.protocols_http },
    { config = {
        type = "record",
        fields = {
          { uri_param_names = {
              type = "set",
              elements = { type = "string" },
              default = { "jwt" },
          }, },
          { cookie_names = {
              type = "set",
              elements = { type = "string" },
              default = {}
          }, },
          { key_claim_name = { type = "string", default = "iss" }, },
          { secret_is_base64 = { type = "boolean", default = false }, },
          { header_prefix = { type = "string", default = "jwt" }, },
          { algorithm = { type = "string", default = "RS256" }, },
          { public_key = { type = "string"}, },
          { private_key = { type = "string"}, },
          { claims_to_verify = {
              type = "set",
              elements = {
                type = "string",
                one_of = { "exp", "nbf" },
          }, }, },
          { scopes_to_validate = {
              type = "set",
              elements = {
                type = "string"
          }, }, },
          { header_mapping = {
              type = "set",
              elements = {
                type = "string"
          }, }, },         
          { scope_claim = { type = "string", default = "scopes" }, },
          { anonymous = { type = "string" }, },
          { run_on_preflight = { type = "boolean", default = true }, },
          { maximum_expiration = {
            type = "number",
            default = 0,
            between = { 0, 31536000 },
          }, },
          { header_names = {
            type = "set",
            elements = { type = "string" },
            default = { "authorization" },
          }, },
        },
      },
    },
  },
  entity_checks = {
    { conditional = {
        if_field = "config.maximum_expiration",
        if_match = { gt = 0 },
        then_field = "config.claims_to_verify",
        then_match = { contains = "exp" },
    }, },
  },
}

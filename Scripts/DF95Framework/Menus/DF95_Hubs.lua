-- DF95_Hubs.lua (A5 patch excerpt / integration)
-- This file shows how to apply action-based require inference.
-- Merge the relevant blocks into your existing DF95_Hubs.lua.

local DF95_RequireRules = require("Scripts/DF95Framework/Lib/DF95_RequireRules")

-- Example: during item normalization, before render / policy gating:
-- (Call this for EVERY item so wrapper menus also benefit.)
local function df95_normalize_item(item)
  -- ensure requires exists for consistency
  if type(item.requires) ~= "table" then item.requires = {} end

  -- Second-pass: infer requires from action string IDs used with NamedCommandLookup
  DF95_RequireRules.apply_action_inference(item)

  return item
end

-- Wherever you iterate hub items:
-- for _, item in ipairs(items) do
--   df95_normalize_item(item)
--   ... existing feature flags + capability gating that sets item.disabled/item.disabled_reason ...
-- end

-- Notes:
-- - keep your existing cause-label renderer:
--     "❌ <Label> (requires sws, js_reascriptapi)" etc.
-- - This patch only adds inference for action string IDs (portable underscore IDs).

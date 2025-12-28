DF95 V3 Templates
=================

Where:
  Scripts/DF95Framework/Templates/

What:
  - DF95_V3_EntryScript_Template.lua
      Start point for new REAPER Action scripts (entrypoints).
      Uses:
        - reaper.GetResourcePath() to locate framework
        - DF95_Core.lua (V3 API)
        - Core.bootstrap() for require() safety (optional)

  - DF95_V3_Module_Template.lua
      Start point for reusable Lua modules loaded via dofile().

Why:
  REAPER does not guarantee a helpful package.path in all environments.
  Many projects therefore bootstrap package.path explicitly in entry scripts
  before using require(). rtk documentation highlights this pattern and shows
  adding a deterministic resource-path based pattern for require(). 

Recommendations:
  1) New scripts: always load DF95_Core.lua first.
  2) Prefer RootResolver/Core.df95_root() instead of hardcoded paths.
  3) Use require() only when you control/initialize package.path.


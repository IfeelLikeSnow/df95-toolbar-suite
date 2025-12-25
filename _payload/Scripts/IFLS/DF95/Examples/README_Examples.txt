DF95 V3 Examples
================

Where:
  Scripts/IFLS/DF95/Examples/

What:
  - DF95_V3_ExampleEntry_Run.lua
      A REAPER Action script (entrypoint). Load it via Action List -> ReaScript: Load.
      It loads DF95_Core.lua, calls Core.bootstrap(), then runs the example module.

Module:
  Scripts/IFLS/DF95/Modules/DF95_V3_ExampleModule.lua

Why this pattern:
  - REAPER scripts should locate dependencies relative to the REAPER resource path.
  - require() depends on package.path. Many projects therefore initialize package.path in the entry script
    before using require(). The rtk docs explicitly demonstrate this approach.

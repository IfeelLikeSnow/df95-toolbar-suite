DF95 Toolbar Suite - Mini Patch (Primary CI Failures)

Adds/ensures the following paths exist at REPO ROOT:

1) Scripts/DF95_IFLS_Register_All_Actions.lua
   - required by Core package @provides [main]

2) Legacy/.keep
   - ensures Legacy/** matches (git does not store empty folders)

3) Toolbars/.keep, Menus/.keep, MenuSets/.keep, Icons/.keep
   - prevents 'no files provided' when UI package maps these folders but they are empty.

How to apply:
- Copy the contents of this mini-patch into your repository ROOT (where .git is).
- Commit + push to main.

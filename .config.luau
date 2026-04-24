-- To be able to run tasks, you will need to install Luumen
-- For more information, see https://luumen.dev.

return {
    package = {
        name = "posthog-luau",
        version = "0.0.0",
        description = "A lightweight PostHog client for Luau, with support for Roblox and standalone runtimes.",
        author = "erlcx",
        license = "MIT"
    },

    tasks = {
        ["install"] = "lute pkg install",
        ["lint"] = "selene src tests examples",
        ["test"] = "lute test",
        ["format"] = "stylua src tests examples",
        ["format:check"] = "stylua --check src tests examples",
        ["ci"] = {"luu lint","luu test","luu run format:check"},
        ["types"] = "lute setup"
    },

    luu = {
         install = {
            tools = true,
            packages = true
        },
    },

    luau = {
        languageMode = "strict",
        aliases = {
            std = "~/.lute/typedefs/1.0.0/std",
            lint = "~/.lute/typedefs/1.0.0/lint",
            lute = "~/.lute/typedefs/1.0.0/lute",
            ["posthog-luau"] = "./src",
            ["dotenv"] = "./Packages/dotenv@v0.1.0/src",
        }
    }
}

-- To be able to run tasks, you will need to install Luumen
-- For more information, see https://luumen.dev.

return {
    project = {
        name = "posthog-luau",
        version = "0.0.0",
        description = "A lightweight PostHog client for Luau, with support for Roblox and standalone runtimes.",
        author = "erlcx",
        license = "MIT"
    },

    install = {
        tools = true,
        packages = true
    },

    tasks = {
        ["lint"] = "selene src",
        ["format"] = "stylua src",
        ["format:check"] = "stylua --check src",

        -- Helper for CI, runs both linting and formatting checks
        ["ci"] = {
            "luu lint",
            "luu run format:check"
        },

        -- Generate lute types for the Luau Language Server
        ["gen:types"] = "lute setup --with-luaurc"
    }
}

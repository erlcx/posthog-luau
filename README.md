# posthog-luau [![CI](https://github.com/erlcx/posthog-luau/actions/workflows/ci.yml/badge.svg)](https://github.com/erlcx/posthog-luau/actions/workflows/ci.yml)

A lightweight PostHog client for Luau, with support for Roblox and standalone runtimes.

This project aims to bring simple, reliable product analytics and feature flags to environments where official PostHog SDKs are not available.

---

## Overview

`posthog-luau` provides a minimal interface for sending analytics events and retrieving feature flags using PostHog’s public ingestion APIs.

It is designed with the constraints of Luau environments in mind:

* No browser APIs
* Limited HTTP capabilities (especially in Roblox)
* Need for small, dependency-free modules

The goal is not to replicate the full PostHog JavaScript SDK, but to provide a focused, idiomatic solution for Luau developers.

---

## Goals

* Simple event tracking (`capture`)
* User identification (`identify`)
* Lightweight batching and flushing
* Feature flag support (remote evaluation)
* Works in:

  * Roblox (via `HttpService`)
  * Lune / Lute / other Luau runtimes
* Minimal footprint and no heavy abstractions

---

## Non-Goals (for now)

* Autocapture (DOM / UI tracking)
* Session replay
* Full parity with browser SDKs
* Local feature flag evaluation with secret keys

---

## Runtime Entrypoints

Use the entrypoint for your runtime.

- `require("posthog-luau/lute")`
- `require("posthog-luau/roblox")`

---

## API

Each runtime exposes the same client shape through `PostHog.new(options)`.

Options:

- `apiKey` - required PostHog project API key
- `host` - defaults to `https://us.i.posthog.com`
- `flushAt` - queue size that triggers an automatic flush
- `flushIntervalSeconds` - time-based flush interval
- `requestTimeoutSeconds` - request timeout for network requests

Methods:

- `capture(event, properties?, distinctId?)`
- `identify(distinctId, properties?)`
- `flush()`
- `getFeatureFlag(key, distinctId?, properties?)`
- `getFeatureFlags(distinctId?, properties?)`

---

## Example

```lua
local PostHog = require("posthog-luau/lute")

local client = PostHog.new({
    apiKey = "phc_xxx",
    host = "https://us.i.posthog.com",
    flushAt = 20,
    flushIntervalSeconds = 10,
    requestTimeoutSeconds = 15
})

client:capture("player_joined", {
    level = 5,
    mode = "ranked"
})

client:identify("player_123", {
    rank = "gold"
})

client:flush()
```

---

## Feature Flags

The SDK will support fetching feature flags from PostHog using the public `/flags` endpoint.

This enables:

* Remote configuration
* A/B testing
* Gradual rollouts

Local evaluation using secure API keys is intentionally out of scope for client-side environments.

---

## Status

This project is in early development.

Expect:

* Breaking changes
* Incomplete features
* Iteration on API design

---

## Why this exists

PostHog is language-agnostic at the API level, but there is no official support for Luau or Roblox.

This project fills that gap by providing:

* A native-feeling Luau API
* Compatibility with PostHog ingestion endpoints
* A foundation for analytics in Roblox experiences

---

## Contributing

Contributions are welcome! Please read the [CONTRIBUTING](./CONTRIBUTING.md) guidelines before submitting a pull request or opening an issue.

---

## License

MIT - see [LICENSE](./LICENSE) for details.

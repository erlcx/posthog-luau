export type Request = {
	method: string,
	url: string,
	headers: { [string]: string }?,
	body: string?,
	timeoutSeconds: number?,
}

export type Response = {
	statusCode: number,
	body: string,
	headers: { [string]: string }?,
}

export type RuntimeAdapter = {
	request: (request: Request) -> Response,
	now: () -> number,
	spawn: (callback: () -> ()) -> (),
	encodeJson: (value: any) -> string,
	decodeJson: (value: string) -> any,
}

export type Properties = { [string]: any }
export type FeatureFlagValue = boolean | string | number

export type PublicOptions = {
	apiKey: string,
	host: string?,
	flushAt: number?,
	flushIntervalSeconds: number?,
	requestTimeoutSeconds: number?,
}

export type Options = PublicOptions & {
	adapter: RuntimeAdapter,
}

export type EventMessage = {
	event: string,
	properties: Properties,
	distinctId: string,
	timestamp: string,
}

export type Client = {
	capture: (self: Client, event: string, properties: Properties?, distinctId: string?) -> (),
	identify: (self: Client, distinctId: string, properties: Properties?) -> (),
	flush: (self: Client) -> (),
	getFeatureFlag: (
		self: Client,
		key: string,
		distinctId: string?,
		properties: Properties?
	) -> FeatureFlagValue?,
	getFeatureFlags: (
		self: Client,
		distinctId: string?,
		properties: Properties?
	) -> { [string]: FeatureFlagValue },
}

export type RuntimeModule = {
	new: (options: PublicOptions) -> Client,
}

return nil

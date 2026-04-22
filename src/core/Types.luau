export type Request = {
	method: string,
	url: string,
	headers: { [string]: string }?,
	body: string?,
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

export type Options = {
	apiKey: string,
	host: string?,
	flushAt: number?,
	adapter: RuntimeAdapter,
}

export type EventMessage = {
	event: string,
	properties: Properties?,
	distinctId: string?,
	timestamp: number?,
}

return nil

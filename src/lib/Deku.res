module Response = {
  type t<'data>
  @send external json: t<'data> => Promise.t<'data'> = "json"
}

@val @scope("window")
external fetch: (string, 'params) => Promise.t<Response.t<'data'>> = "fetch"

let makeParams = (body) =>
  {
    "method": "POST",
    "body": Js.Json.stringifyAny(body)
  }

let nodeBaseUri = "http://127.0.0.1:4440/"

open Promise

let fetch = (path, payload) => {
  let options = makeParams(payload)

  fetch(nodeBaseUri ++ path, options)
  ->then(Response.json)
}

let blockLevel = () => {
  fetch("block-level", Js.null)
  ->then(data => data["level"])
}

let ticketBalance: (~address: Taquito.Address.t, ~ticket: string) => Promise.t<int> =
  (~address: string, ~ticket: string) => {
    fetch(
      "ticket-balance",
      {
        "address": address,
        "ticket": ticket
      }
    )
    ->then(data => data["amount"])
  }

let userOperationToJson = (operation) => {
  let json = DekuOperation.InitialOperation.toJSON(operation.DekuOperation.data.initialOperation)

  {
    "user_operation": {
      "hash": Taquito.Buffer.toHex(operation.DekuOperation.hash),
      "key": Taquito.PublicKey.toString(operation.key),
      "signature": operation.signature,
      "nonce": operation.nonce,
      "block_height": operation.blockHeight,
      "data": {
        "hash": Taquito.Buffer.toHex(operation.data.hash),
        "source": operation.data.source,
        "initial_operation": json
      }
    }
  }
}

let gossip = (operation): Promise.t<unit> => {
  fetch(
    "user-operation-gossip",
    userOperationToJson(operation)
  )
}

let getContractStorage = (~address: string) => {
  fetch(
    "contract-storage",
    { "address": address }
  )
}

let tickets = (~address: string) => {
  fetch(
    "available-tickets",
    { "address": address }
  )
}
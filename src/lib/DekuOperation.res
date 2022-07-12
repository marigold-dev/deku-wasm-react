module Ticket = {
  type t = { ticketer: string, data: string }
}

module InitialOperation = {
  type t =
    | ContractOrigination({
        code: string,
        storage: string,
        tickets: array<Ticket.t>
      })
    | ContractInvocation({
        address: Taquito.Address.t,
        argument: string,
        tickets: array<Ticket.t>
      })

  let originate = (~code, ~storage, ~tickets) =>
    ContractOrigination({ code, storage, tickets })

  let invoke = (~address, ~argument, ~tickets) =>
    ContractInvocation({ address, argument, tickets })

  let toJSON = (initialOperation) => {
    open Js.Json

    switch initialOperation {
    | ContractOrigination({ code, storage, tickets:_ }) => {
        array([
          string("Contract_origination"),
          [
            ("payload", array([
              string("Wasm"),
              [
                ("code", string(code)),
                ("storage", string(storage))
              ]
              ->Js.Dict.fromArray
              ->object_
            ])),
            ("tickets", array([]))
          ]
          ->Js.Dict.fromArray
          ->object_
        ])
      }
    | ContractInvocation({ address, argument, tickets:_ }) => {
        array([
          string("Contract_invocation"),
          [
            ("to_invoke", string(address)),
            ("argument", array([
              string("Wasm"),
              string(argument)
            ])),
            ("tickets", array([]))
          ]
          ->Js.Dict.fromArray
          ->object_
        ])
      }
    }
  }
}

module Operation = {
  type t =
    {
      hash: Taquito.Hash.t,
      source: Taquito.Address.t,
      initialOperation: InitialOperation.t
    }

  let make = (~hash, ~source, ~initialOperation) => {
    { hash, source, initialOperation }
  }
}

type t =
  {
    hash: Taquito.Hash.t,
    key: Taquito.PublicKey.t,
    signature: Taquito.Signature.t,
    nonce: int,
    blockHeight: int,
    data: Operation.t
  }

let make = (~hash, ~key, ~signature, ~nonce, ~blockHeight, ~data) => {
  { hash, key, signature, nonce, blockHeight, data }
}
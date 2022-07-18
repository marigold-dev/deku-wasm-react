module Ticket = {
  type ticket_id = string
  type amount = int

  type t = (ticket_id, amount)

  let make = (ticket_id, amount) => (ticket_id, amount)
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

  let ticketsToJson = (tickets) => {
    open Js.Json

    tickets
    ->Belt.Array.mapWithIndex((idx, (ticket_id, amount)) => {
      array([
        array([ string(ticket_id), number(Js.Int.toFloat(amount)) ]),
        array([ number(Js.Int.toFloat(idx)), null ])
      ])
    })
    ->array
  }

  let toJSON = (initialOperation) => {
    open Js.Json

    switch initialOperation {
    | ContractOrigination({ code, storage, tickets }) => {
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
            ("tickets", ticketsToJson(tickets))
          ]
          ->Js.Dict.fromArray
          ->object_
        ])
      }
    | ContractInvocation({ address, argument, tickets }) => {
        array([
          string("Contract_invocation"),
          [
            ("to_invoke", string(address)),
            ("argument", array([
              string("Wasm"),
              string(argument)
            ])),
            ("tickets", ticketsToJson(tickets))
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
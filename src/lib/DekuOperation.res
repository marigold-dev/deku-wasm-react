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
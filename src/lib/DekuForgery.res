
let serializeOperationForHash = (initialOperation, source: Taquito.Address.t) => {
  open Js.Json

  array([
    string(source),
    initialOperation
  ])
}

let serializeUserOperation = (hash, source, initialOperation) => {
  open Js.Json

  [
    ("hash", string(hash)),
    ("source", string(source)),
    ("initial_operation", initialOperation)
  ]
  ->Js.Dict.fromArray
  ->object_
}

let serializeUserOperationForHash = (nonce, blockHeight, data) => {
  open Js.Json

  array([
    nonce
    ->Js.Int.toFloat
    ->number,
    blockHeight
    ->Js.Int.toFloat
    ->number,
    data
  ])
}

open Promise

@module("crypto")
external randomBytes : int => Js_typed_array2.Int8Array.t = "randomBytes"

let randomInt = () => {
    let size = 4

    size
    ->randomBytes
    ->Js_typed_array2.Int8Array.reduce(
          (. acc, elt) => Int32.logor(Int32.shift_left(acc, 8), Int32.of_int(elt)),
          0l
      )
    ->Int32.to_int
}

let forge = (initialOperation, ~signer, ~blockHeight) => {
  let nonce = randomInt()

  Taquito.Signer.publicKeyHash(signer)
  ->thenResolve(pkh => {
    let json = DekuOperation.InitialOperation.toJSON(initialOperation)

    let hash =
      json
      ->serializeOperationForHash(pkh)
      ->Js.Json.stringify
      ->Taquito.Buffer.ofString
      ->Taquito.Hash.hash(32)

    let operation = DekuOperation.Operation.make(
      ~hash,
      ~source=pkh,
      ~initialOperation
    )

    let payload =
      serializeUserOperationForHash(
        nonce,
        blockHeight,
        serializeUserOperation(
          Taquito.Buffer.toHex(operation.hash),
          operation.source,
          json,
        )
      )
      ->Js.Json.stringify

    let hash =
      payload
      ->Taquito.Buffer.ofString
      ->Taquito.Hash.hash(32)

    (payload, hash, operation)
  })
  ->then(((payload, hash, operation)) => {
    Taquito.Signer.sign(signer, payload, hash)
    ->thenResolve(signature => (signature, hash, operation))
  })
  ->then(((signature, hash, operation)) => {
    Taquito.Signer.publicKey(signer)
    ->thenResolve(key => {
      DekuOperation.make(~hash, ~signature, ~key, ~nonce, ~blockHeight, ~data=operation)
    })
  })
}

let getContractAddressFromOperation = (operation: DekuOperation.t) => {
  operation.hash
  ->Taquito.Hash.hash(20)
  ->Taquito.Buffer.b58encode(Taquito.Prefix.dk1)
}

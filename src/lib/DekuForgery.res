
let serializeContractOrigination: (DekuOperation.InitialOperation.t) => Js.Json.t = %raw("
  (operation) => {
    return [
      \"Contract_origination\",
      {
        payload: [
          \"Wasm\",
          { code: operation.code, storage: operation.storage }
        ],
        tickets: operation.tickets
      }
    ]
  }
")

let serializeContractInvocation: (DekuOperation.InitialOperation.t) => Js.Json.t = %raw("
  (operation) => {
    return [
      \"Contract_invocation\",
      {
        to_invoke: operation.address,
        argument: [
          \"Wasm\",
          operation.argument
        ],
        tickets: operation.tickets
      }
    ]
  }
")

let serializeOperationForHash : (Taquito.Address.t, Js.Json.t) => Js.Json.t =
%raw("
  (source, initialOperation) => {
    return [
      source,
      initialOperation
    ]
  }
")

let serializeUserOperation : (string, string, Js.Json.t) => Js.Json.t = %raw("
  (hash, source, initial_operation) => {
    return { hash, source, initial_operation }
  }
")

let serializeUserOperationForHash: (int, int, Js.Json.t) => Js.Json.t = %raw("
  (nonce, blockHeight, data) => {
    return [
      nonce,
      blockHeight,
      data
    ]
  }
")

let tap = (x, f) => {
  f(x)
  x
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
    let json = switch initialOperation {
    | DekuOperation.InitialOperation.ContractOrigination(_) => serializeContractOrigination(initialOperation)
    | ContractInvocation(_) => serializeContractInvocation(initialOperation)
    }

    let hash =
      serializeOperationForHash(pkh, json)
      ->Js.Json.stringify
      ->tap(Js.log)
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
      ->tap(Js.log)
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
  ->Taquito.Buffer.b58encode(Taquito.Buffer.make([ 1, 146, 6 ]))
}

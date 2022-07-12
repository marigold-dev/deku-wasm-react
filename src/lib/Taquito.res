open Promise

module Buffer = {
  type t

  @new
  external make : array<int> => t = "Uint8Array"

  type encoder
  @new external textEncoder : string => encoder = "TextEncoder"
  @send external encode : encoder => string => t = "encode"

  let ofString = value => encode(textEncoder("utf-8"), value)

  @module("@taquito/utils")
  external ofHex : string => t = "hex2buf"

  @module("@taquito/utils")
  external toHex: 'buffer => string = "buf2hex"

  @val @scope("Buffer")
  external bufferFrom: t => 'buffer = "from"

  let toHex = t => t->bufferFrom->toHex

  @send external _toString : 'buffer => string = "toString"

  @module("@taquito/utils")
  external b58cencode : t => t => string = "b58cencode"

  let b58encode = (t, prefix) => {
    b58cencode(t, prefix)
  }
}

module Prefix = {
  let dk1 = Buffer.make([ 1, 146, 6 ])
}

module Hash = {
  type t = Buffer.t

  @module("@stablelib/blake2b")
  external hash : Buffer.t => int => Buffer.t = "hash"
}

module Signature = {
  type t = string

  let ofString = t => t
}

module PublicKey = {
  type t = string

  let ofString = t => t

  let toString = t => t
}

module Address = {
  type t = string

  let ofString: string => t = t => t
}

module Signer = {
  type t

  @scope("InMemorySigner") @module("@taquito/signer")
  external ofPrivateKey: string => Promise.t<t> = "fromSecretKey"

  @send external publicKeyHash : t => Promise.t<Address.t> = "publicKeyHash"

  @send external publicKey : t => Promise.t<PublicKey.t> = "publicKey"

  @get external key : t => 'key = "_key"
  @send external sign : 'key => string => Buffer.t => Promise.t<'a> = "sign"

  let sign = (signer, data, hash) => {
    // TODO: change this so we could sign this using beaconsdk
    signer
    ->key
    ->sign(data, hash)
    ->thenResolve(signature =>
      Signature.ofString(signature["prefixSig"])
    )
  }
}


open Promise

type modal =
  | Receipt(Deku.receipt)

type notification =
  | NoNotification
  | Success(string)
  | Error(string)

type t = {
  signer: option<Taquito.Signer.t>,
  contractAddress: option<string>,
  contractTickets: option<array<(string, int)>>,
  storage: option<string>,
  tickets: option<array<(string, int)>>,
  selectedTickets: array<(string, int)>,
  modal: option<modal>,
  notification: notification
}

type action =
  | Authorize(string)
  | MakeOperation(DekuOperation.InitialOperation.t)
  | SetSelectedTickets(array<(string, int)>)
  | UpdateStorage
  | UpdateTickets
  | GetReceipt(DekuOperation.t)
  | CloseModal
  | CloseNotification

type rec effect =
  | Action(action)
  | Defer(Promise.t<effect>)
  | UpdateState(t => t)
  | Noop

@val external setTimeout : (unit => unit) => int => unit = "setTimeout"

let actionHandler = (~state, ~log, action) => {
  switch action {
  | Authorize(privateKey) => {
      let promise =
        privateKey
        ->Taquito.Signer.ofPrivateKey
        ->then(signer => {
          signer
          ->Taquito.Signer.publicKeyHash
          ->then(address => {
            log(`Authenticated as ${address}`, [])
            Deku.tickets(~address)
          })
          ->thenResolve(tickets => {
            UpdateState(state => {
              ...state,
              signer: Some(signer),
              tickets: Some(tickets),
              notification: Success("Authenticated successfuly")
            })
          })
        })

      Defer(promise)
    }
  | MakeOperation(operation) => {
      let signer = switch state.signer {
      | Some(signer) => signer
      | None => failwith("Signer is not available")
      }

      let promise = {
        Deku.blockLevel()
        ->then(blockHeight => DekuForgery.forge(operation, ~signer, ~blockHeight))
        ->then(operation => {
          open DekuOperation

          let hash = Taquito.Buffer.toHex(operation.hash)

          let effect =
            switch operation.data.initialOperation {
            | ContractOrigination(_) => {
                let address = DekuForgery.getContractAddressFromOperation(operation)
                let effect = UpdateState(state => { ...state, contractAddress: Some(address) })
                log(
                  `Originating contract ${address} with operation ${hash}`,
                  [ ("Use this contract", () => effect) ]
                )
                effect
              }
            | ContractInvocation({ address, _ }) => {
                log(
                  `Invoking contract ${address}`,
                  [ ("Update storage", () => Action(UpdateStorage)) ]
                )

                let promise =
                  Promise.make((resolve, _reject) => {
                    log("Updating storage in 10s", [])
                    setTimeout(() => resolve(. Action(UpdateStorage)), 10000)
                  })

                Defer(promise)
              }
            }

          operation
          ->Deku.gossip
          ->thenResolve(_ => {
            log(
              `Operation ${hash} sent`,
              [
                ("Receipt", () => Action(GetReceipt(operation))),
                ("Repeat", () => Action(action))
              ]
            )
            effect
          })
        })
      }

      Defer(promise)
    }
  | UpdateStorage => {
      log(`Updating storage and tickets`, [])
      let address = Belt.Option.getExn(state.contractAddress)

      let promise =
        all2((
          Deku.getContractStorage(~address),
          Deku.tickets(~address),
        ))
        ->thenResolve(((storage, tickets)) =>
          UpdateState(state => {
            ...state,
            storage: Some(Js.Json.stringify(storage)),
            contractTickets: Some(tickets),
            notification: Success("Storage has been updated")
        }))

      Defer(promise)
    }
  | UpdateTickets => {
      let promise =
        state.signer
        ->Belt.Option.getExn
        ->Taquito.Signer.publicKeyHash
        ->then(address => Deku.tickets(~address))
        ->thenResolve(tickets => UpdateState(state => { ...state, tickets: Some(tickets) }))

      Defer(promise)
    }
  | SetSelectedTickets(tickets) => {
      UpdateState(state => { ...state, selectedTickets: tickets })
    }
  | GetReceipt(operation) => {
      let promise =
        Deku.receipt(~hash=Taquito.Buffer.toHex(operation.hash))
        ->thenResolve(receipt => {
          switch receipt {
          | Some(receipt) =>
            UpdateState(state => {
              ...state,
              modal: Some(Receipt(receipt))
            })
          | None =>
            UpdateState(state => {
              ...state,
              notification: Error("Receipt not found, wait a few seconds.")
            })
          }
        })

      Defer(promise)
    }
  | CloseModal =>
      UpdateState(state => { ...state, modal: None })
  | CloseNotification =>
      UpdateState(state => { ...state, notification: NoNotification })
  }
}

let rec dispatch = (~state, ~stateDispatch, ~log, effect) => {
  switch effect {
  | Action(action) =>
    action
    ->actionHandler(~state, ~log)
    ->dispatch(~state, ~stateDispatch, ~log)
  | Defer(promise) =>
    promise
    ->thenResolve(dispatch(~state, ~stateDispatch, ~log))
    ->catch((err) => {
      Js.log(err)
      switch err {
      | JsError(err) => {
          let message =
            Belt.Option.getWithDefault(
              Js.Exn.message(err),
              "Unknown error",
            )
          resolve(dispatch(~state, ~stateDispatch, ~log, UpdateState(state => { ...state, notification: Error(message)})))
        }
      | err => raise(err)
      }

    })
    ->ignore
  | UpdateState(fn) => stateDispatch(fn)
  | Noop => ()
  }
}

let default = {
  signer: None,
  contractAddress: None,
  contractTickets: None,
  storage: None,
  tickets: None,
  selectedTickets: [],
  modal: None,
  notification: NoNotification
}

let useState = () => {
  let (state, setState) = React.useState(_ => default)
  let (log, setLog) = React.useState(_ => [])

  let addLog = (entry, actions) => {
    setLog(log => Belt.Array.concat(log, [ (entry, actions) ]))
  }

  (state, log, dispatch(~state, ~stateDispatch=setState, ~log=addLog))
}

let context = React.createContext((_eff: effect) => ())
module Provider = {
  let provider = React.Context.provider(context)

  @react.component
  let make = (~value, ~children) => {
    React.createElement(provider, {"value": value, "children": children})
  }
}

let useDispatch = () => React.useContext(context)
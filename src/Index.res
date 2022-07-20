
let defaultContract =
  "(module
  (import \"env\" \"syscall\" (func $syscall (param i64) (result i32)))
  (memory (export \"memory\") 1)

  (func $increment (param $by i32)
    i32.const 0

    i32.const 0
    i32.load
    local.get $by
    i32.add

    i32.store)

  (func (export \"main\") (param i32) (result i64 i64 i64)
    local.get 0
    i32.load

    (if
      (then
        i32.const 1
        call $increment)
      (else
        i32.const -1
        call $increment))

    i64.const 0
    i64.const 4
    i64.const 99))"

let defaultStorage = "\"\u0000\u0000\u0000\u0000\""

let decodeJSONCodeEditor = (editor, dispatch) => {
  let contents =
    editor
    ->Belt.Option.getExn
    ->CodeMirror.contents

  let value =
    switch Js.Json.parseExn(contents) {
    | exception _ => {
        dispatch(State.UpdateState(state => { ...state, notification: Error("Invalid JSON")}))
        None
      }
    | value => Some(value)
    }

  switch Belt.Option.map(value, Js.Json.classify) {
  | Some(Js.Json.JSONString(value)) => Some(value)
  | Some(_) => {
      dispatch(UpdateState(state => { ...state, notification: Error("Only strings are allowed")}))
      None
    }
  | None => None
  }
}

@val external prompt : string => Js.Nullable.t<string> = "prompt"

@react.component
let default = () => {
  let code: React.ref<option<CodeMirror.t>> = React.useRef(None)
  let storage: React.ref<option<CodeMirror.t>> = React.useRef(None)
  let arguments: React.ref<option<CodeMirror.t>> = React.useRef(None)

  let (currentTab, selectTab) = Tab.useTab()

  let (state, log, dispatch) = State.useState()

  let authorize = () => {
    switch prompt("Private key")->Js.Nullable.toOption {
    | Some(pk) when pk != "" => dispatch(Action(Authorize(pk)))
    | Some(_) | None => ()
    }
  }

  let modal =
    Belt.Option.mapWithDefault(
      state.modal,
      React.null,
      modal =>
        switch modal {
        | Receipt(receipt) => <Receipt receipt />
        }
    )

  let notification =
    switch state.notification {
    | NoNotification => React.null
    | Error(message) =>
      <Notification onClose={_ => dispatch(Action(CloseNotification))}>
        <div className="text-red-400 pr-2">
          <Icon.Exclamation />
        </div>
        {React.string(message)}
      </Notification>
    | Success(message) =>
      <Notification onClose={_ => dispatch(Action(CloseNotification))}>
        <div className="text-green-400 pr-2">
          <Icon.Check />
        </div>
        {React.string(message)}
      </Notification>
    }

  React.useEffect1(() => {
    switch (storage.current, state.storage) {
    | (Some(storage), Some(value)) => {
        let size =
          storage
          ->CodeMirror.contents
          ->String.length

        CodeMirror.dispatch(storage, {
          changes: {
            from: 0,
            to_: Some(size),
            insert: value
          }
        })
      }
    | _ => ()
    }

    None
  }, [state.storage])

  let originate = () => {
    let code =
      code.current
      ->Belt.Option.getExn
      ->CodeMirror.contents

    switch decodeJSONCodeEditor(storage.current, dispatch) {
    | Some(storage) => {
        let operation = DekuOperation.InitialOperation.originate(~code, ~storage, ~tickets=state.selectedTickets)
        dispatch(Action(MakeOperation(operation)))
      }
    | None => ()
    }
  }

  let invoke = () => {
    let address = switch state.contractAddress {
    | Some(address) => address
    | None => failwith("Contract address is not available")
    }
    switch decodeJSONCodeEditor(arguments.current, dispatch) {
    | Some(argument) => {
        let operation = DekuOperation.InitialOperation.invoke(~address, ~argument, ~tickets=state.selectedTickets)
        dispatch(Action(MakeOperation(operation)))
      }
    | None => ()
    }
  }

  let updateStorage = () => {
    dispatch(Action(UpdateStorage))
  }

  let changeNode = () => {
    switch prompt("Node URL")->Js.Nullable.toOption {
    | Some(node) when node != "" => Deku.nodeBaseUri := node
    | Some(_) | None => ()
    }
  }

  let changeTickets = (tickets) => {
    dispatch(Action(SetSelectedTickets(tickets)))
  }

  <State.Provider value={dispatch}>
    <main className="h-full max-h-full w-full bg-deku-5 flex flex-col">
      <Next.Head>
        <title>{React.string("Deku IDE")}</title>
      </Next.Head>

      {modal}
      {notification}

      <header className="flex items-center py-4 px-8 bg-deku-4 h-auto w-full">
        {
          switch state.signer {
          | Some(_) => <ToolbarButton title="Originate contract" icon={<Icon.Upload />} onClick=originate />
          | None => React.null
          }
        }

        <ToolbarButton title="Change node URL" icon={<Icon.Server />} onClick=changeNode />
        <ToolbarButton title="Set current private key" icon={<Icon.Key />} onClick=authorize  />

        <div className="flex text-white p-2 my-2 mx-8 bg-deku-5 rounded-full align-self-center">
          <button
            className="bg-deku-6 p-2 rounded-full disabled:text-gray-400 hover:scale-110 transition-all"
            disabled={Belt.Option.isNone(state.contractAddress)}
            title="Invoke current contract"
            onClick=(_ => invoke())
          >
            <Icon.Play />
          </button>
          <p className="py-2 px-6 pl-4">
            {
              state.contractAddress
              ->Belt.Option.getWithDefault("No contract yet")
              ->React.string
            }
          </p>

          {
            switch state.contractAddress {
            | Some(_) =>
              <button className="text-white pr-4 hover:scale-110 transition-all" onClick={_ => updateStorage()} title="Update storage and tickets">
                <Icon.Refresh />
              </button>
            | None => React.null
            }
          }

        </div>
      </header>

      <nav className="w-full flex flex-row">
        <Tab
          currentTab
          tab=Tab.Source
          icon={<Icon.Code />}
          label="Source"
          onSelect=selectTab
        />
        <Tab
          currentTab
          tab=Tab.Storage
          icon={<Icon.Database />}
          label="Storage"
          onSelect=selectTab
        />

        {
          switch state.contractAddress {
          | Some(_) =>
            <Tab
              currentTab
              tab=Tab.Argument
              icon={<Icon.Adjustments />}
              label="Argument"
              onSelect=selectTab
            />
          | None =>
            React.null
          }
        }

        {switch state.tickets {
        | Some(_) =>
          <Tab
            currentTab
            tab=Tab.Tickets
            icon={<Icon.Ticket />}
            label="Tickets"
            onSelect=selectTab
          />
        | None =>
          React.null
        }}

        <Tab
          currentTab
          tab=Tab.Log
          icon={<Icon.Table />}
          label="Log"
          onSelect=selectTab
        />

        <p className="text-white text-sm text-right px-4 pt-2 w-full">
          {switch Belt.Array.get(log, Belt.Array.length(log) - 1) {
          | None => React.null
          | Some((entry, _)) => React.string(entry)
          }}
        </p>
      </nav>

      <TabContent tab=Tab.Source currentTab>
        <CodeEditor
          language=#Wast
          code=defaultContract
          state=code
          extensions={[
            CodeMirror.wasmLinter(),
            CodeMirror.lintGutter()
          ]}
        />
      </TabContent>

      <TabContent tab=Tab.Storage currentTab>
        <CodeEditor
          language=#JSON
          code=defaultStorage
          state=storage
          extensions={[ CodeMirror.jsonLinter() ]}
        />
      </TabContent>

      <TabContent tab=Tab.Argument currentTab>
        <CodeEditor
          language=#JSON
          code="\"\""
          state=arguments
          extensions={[ CodeMirror.jsonLinter() ]}
        />
      </TabContent>

      <TabContent tab=Tab.Tickets currentTab>
        <div className="container text-white w-full mx-auto my-4 px-8">
          {switch state.tickets {
          | Some(tickets) =>
            <>
              <Title.H2 label="User tickets" />
              <TicketTable tickets=tickets onChange=changeTickets />
            </>
          | None => React.null
          }}

          {switch state.contractTickets {
          | Some(tickets) =>
            <>
              <Title.H2 label="Contract tickets" />
              <TicketTable tickets />
            </>
          | None => React.null
          }}
        </div>
      </TabContent>

      <TabContent tab=Tab.Log currentTab>
        <LogFile log />
      </TabContent>

    </main>
  </State.Provider>
}
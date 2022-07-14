
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

let decodeJSONCodeEditor = editor => {
  editor
  ->Belt.Option.getExn
  ->CodeMirror.contents
  ->Js.Json.parseExn
  ->Js.Json.decodeString
  ->Belt.Option.getExn
}

@val external prompt : string => option<string> = "prompt"

@react.componentrafa
let default = () => {
  let code: React.ref<option<CodeMirror.t>> = React.useRef(None)
  let storage: React.ref<option<CodeMirror.t>> = React.useRef(None)
  let arguments: React.ref<option<CodeMirror.t>> = React.useRef(None)

  let (currentTab, selectTab) = Tab.useTab()

  let (state, log, dispatch) = State.useState()

  let authorize = () => {
    switch prompt("Private key") {
    | Some(pk) => dispatch(Action(Authorize(pk)))
    | None => ()
    }
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
    let storage = decodeJSONCodeEditor(storage.current)

    let operation = DekuOperation.InitialOperation.originate(~code, ~storage, ~tickets=[])
    dispatch(Action(MakeOperation(operation)))
  }

  let invoke = () => {
    let address = switch state.contractAddress {
    | Some(address) => address
    | None => failwith("Contract address is not available")
    }
    let argument = decodeJSONCodeEditor(arguments.current)

    let operation = DekuOperation.InitialOperation.invoke(~address, ~argument, ~tickets=[])
    dispatch(Action(MakeOperation(operation)))
  }

  let updateStorage = () => {
    dispatch(Action(UpdateStorage))
  }

  <main className="h-full max-h-full w-full bg-deku-5 flex flex-col">
    <header className="flex items-center py-4 px-8 bg-deku-4 h-auto w-full">
      {
        switch state.signer {
        | Some(_) => <ToolbarButton icon={<Icon.Upload />} onClick=originate />
        | None => React.null
        }
      }

      <ToolbarButton icon={<Icon.Key />} onClick=authorize  />

      <div className="flex text-white p-2 my-2 mx-8 bg-deku-5 rounded-full align-self-center">
        <button
          className="bg-deku-6 p-2 rounded-full disabled:text-gray-400"
          disabled={Belt.Option.isNone(state.contractAddress)}
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
            <button className="text-white pr-4" onClick={_ => updateStorage()}>
              <Icon.Download />
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
        {switch Belt.Array.get(log, 0) {
        | None => React.null
        | Some(entry) => React.string(entry)
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
      <CodeEditor language=#JSON code="\"\"" state=storage />
    </TabContent>

    <TabContent tab=Tab.Argument currentTab>
      <CodeEditor language=#JSON code="\"\"" state=arguments />
    </TabContent>

    <TabContent tab=Tab.Tickets currentTab>
      {switch state.tickets {
      | Some(tickets) => <TicketTable tickets=tickets />
      | None => React.null
      }}
    </TabContent>

    <TabContent tab=Tab.Log currentTab>
      <LogFile log />
    </TabContent>

  </main>
}
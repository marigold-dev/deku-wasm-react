
let defaultContract =
  "(module
  (import \"env\" \"syscall\" (func $syscall (param i64) (result i32)))
  (memory (export \"memory\") 1)
  (func (export \"main\") (param i32) (result i64 i64 i64)
    local.get 0
    i32.load
    (if
      (then
        i32.const 0
        i32.const 0
        i32.load
        i32.const 1
        i32.add
        i32.store)
      (else
        i32.const 0
        i32.const 0
        i32.load
        i32.const -1
        i32.add
        i32.store))
    i64.const 0
    i64.const 4
    i64.const 99))"

module Tab = {
  type t =
    | Source
    | Storage
    | Argument
    | Tickets

  @react.component
  let make = (~currentTab, ~tab, ~icon, ~label, ~onSelect) => {
    let style = if currentTab == tab { "bg-deku-1" } else { "bg-deku-3" }

    <button className={"flex px-4 py-1 text-white " ++ style} onClick={_ => onSelect(tab)} >
      {icon}
      <span className="px-2">{React.string(label)}</span>
    </button>
  }

  let useTab = () => {
    let (currentTab, setCurrentTab) = React.useState(_ => Source)
    let selectTab = (tab) => setCurrentTab(_ => tab)

    (currentTab, selectTab)
  }
}

module TabContent = {
  @react.component
  let make = (~currentTab, ~tab, ~children) => {
    let visibility = if currentTab == tab { "" } else { "hidden" }

    <div className={"contents h-full " ++ visibility}>
      {children}
    </div>
  }
}

module ToolbarButton = {
  @react.component
  let make = (~animate=false, ~icon, ~onClick) => {
    <button className="bg-deku-2 cog m-2 p-2 rounded" onClick={_ => onClick()}>
      {
        if animate {
          <div className="animate-spin">
            {icon}
          </div>
        } else {
          icon
        }
      }
    </button>
  }
}

@val
external prompt : string => Js.Nullable.t<string> = "prompt"

let userSigner = () => {
  let (signer, setSigner) = React.useState(() => None)

  let importFromKey = () => {
    let key = prompt("Import from a private key")
    switch key->Js.Nullable.toOption {
    | Some(key) when key != "" =>
      key
      ->Taquito.Signer.ofPrivateKey
      ->Promise.thenResolve(signer => setSigner(_ => Some(signer)))
      ->ignore
    | _ => ()
    }
  }

  (signer, importFromKey)
}

@react.component
let default = () => {
  let code: React.ref<option<CodeMirror.CM.t>> = React.useRef(None)
  let storage: React.ref<option<CodeMirror.CM.t>> = React.useRef(None)
  let arguments: React.ref<option<CodeMirror.CM.t>> = React.useRef(None)

  let (currentTab, selectTab) = Tab.useTab()

  let (signer, importKey) = userSigner()

  let (loading, setLoading) = React.useState(_ => false)
  let (currentAddress, setCurrentAddress) = React.useState(_ => None)

  let originate = () => {
    switch (signer, code.current, storage.current) {
    | (Some(signer), Some(code), Some(storage)) => {
        let code = CodeMirror.CM.contents(code)
        let storage = CodeMirror.CM.contents(storage)

        open Promise

        setLoading(_ => true)

        Deku.blockLevel()
        ->then((blockHeight) => {
          let storage =
            storage
            ->Js.Json.parseExn
            ->Js.Json.decodeString
            ->Belt.Option.getExn

          DekuOperation.InitialOperation.originate(
            ~code,
            ~storage,
            ~tickets=[]
          )
          ->DekuForgery.forge(~signer, ~blockHeight)
        })
        ->thenResolve((operation) => {
          let address = DekuForgery.getContractAddressFromOperation(operation)
          setCurrentAddress(_ => Some(address))
          operation
        })
        ->then(Deku.gossip)
        ->thenResolve(() => setLoading(_ => false))
        ->ignore
      }
    | _ => ()
    }
  }

  let invoke = () => {
    switch (signer, currentAddress, arguments.current) {
    | (Some(signer), Some(address), Some(arguments)) => {
        let argument = CodeMirror.CM.contents(arguments)

        open Promise

        setLoading(_ => true)

        Deku.blockLevel()
        ->then(blockHeight => {
          let argument =
            argument
            ->Js.Json.parseExn
            ->Js.Json.decodeString
            ->Belt.Option.getExn

          DekuOperation.InitialOperation.invoke(
            ~address,
            ~argument,
            ~tickets=[]
          )
          ->DekuForgery.forge(~signer, ~blockHeight)
        })
        ->then(Deku.gossip)
        ->thenResolve(() => setLoading(_ => false))
        ->ignore
      }
    | _ => ()
    }
  }

  <main className="h-full w-full bg-deku-5 flex flex-col">
    <header className="py-4 px-8 bg-deku-4 h-auto w-full">
      <ToolbarButton animate=loading icon={<Icon.Cog />} onClick=originate />
      <ToolbarButton icon={<Icon.Play />} onClick=invoke />
      <ToolbarButton icon={<Icon.Key />} onClick=importKey  />

      {switch currentAddress {
        | Some(address) =>
          <b className="text-white">{React.string(address)}</b>
        | None =>
          <b className="text-white">{React.string("No contract yet, originate one or enter an address.")}</b>
      }}

    </header>

    <nav className="w-full flex">
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
        switch currentAddress {
        | Some(_) =>
          <Tab
            currentTab
            tab=Tab.Argument
            icon={<Icon.Adjustments />}
            label="Argument"
            onSelect=selectTab
          />
        | None => React.null
        }
      }
    </nav>

    <TabContent tab=Tab.Source currentTab>
      <CodeMirror language=#Wast code=defaultContract state=code />
    </TabContent>

    <TabContent tab=Tab.Storage currentTab>
      <CodeMirror language=#JSON code="\"\"" state=storage />
    </TabContent>

    <TabContent tab=Tab.Argument currentTab>
      <CodeMirror language=#JSON code="\"\"" state=arguments />
    </TabContent>
  </main>
}
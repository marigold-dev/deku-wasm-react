module CM = {
  type extension

  module Language = {
    type _lang

    @module("@codemirror/legacy-modes/mode/wast") external wast : _lang = "wast"

    @module("@codemirror/language") external streamLanguage: 'a = "StreamLanguage"

    @module("@codemirror/lang-json") external jsonLanguage: unit => extension = "json"

    let streamLanguageDefine = (language: _lang) =>
      streamLanguage["define"](language)

    type t =
      [ #Wast
      | #JSON ]

    let toExtension = (lang) =>
      switch (lang) {
      | #Wast => streamLanguageDefine(wast)
      | #JSON => jsonLanguage()
      }
  }

  module Text = {
    type t

    @send external toString : t => string = "toString"
  }

  type state = {
    doc: Text.t
  }

  type t = {
    state: state
  }

  type editorConfig = {
    doc: string,
    parent: Dom.element,
    extensions: array<extension>
  }

  @module("codemirror")
  external basicSetup : extension = "basicSetup"

  @new @module("@codemirror/view") external make : editorConfig => t = "EditorView"

  @module("@uiw/codemirror-theme-darcula") external darculaTheme: extension = "darcula"

  let contents = (cm) =>
    Text.toString(cm.state.doc)
}

@react.component
let make = (~state: React.ref<'a>, ~code: string, ~language: CM.Language.t) => {
  let inputRef = React.useRef(Js.Nullable.null)
  let cmRef: React.ref<option<CM.t>> = React.useRef(None)

  React.useEffect0(() => {
      switch (cmRef.current, inputRef.current->Js.Nullable.toOption) {
      | (None, Some(input)) =>
          let cm = CM.make({
            doc: code,
            parent: input,
            extensions: [
              CM.basicSetup,
              CM.darculaTheme,
              CM.Language.toExtension(language)
            ]
          })
          state.current = Some(cm)
          cmRef.current = Some(cm)
      | _ => ()
      }

      None
  })

  <div className="h-full" ref={ReactDOM.Ref.domRef(inputRef)}></div>
}
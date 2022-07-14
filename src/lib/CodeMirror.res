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

type change = {
  from: int,
  @as("to") to_: option<int>,
  insert: string
}

type transaction = {
  changes: change
}

type diagnostic = {
  from: int,
  @as("to") to_: int,
  severity: string,
  message: string
}

type linterConfig = {
  delay: option<int>
}

@module("codemirror")
external basicSetup : extension = "basicSetup"

@new @module("@codemirror/view") external make : editorConfig => t = "EditorView"

@module("@uiw/codemirror-theme-darcula") external darculaTheme: extension = "darcula"

@module("@codemirror/lint") external linter : (t => array<diagnostic>) => linterConfig => extension = "linter"
@module("@codemirror/lint") external lintGutter : unit => extension = "lintGutter"

let contents = (cm) =>
  Text.toString(cm.state.doc)

@send external dispatch : t => transaction => unit = "dispatch"

let wasmLinter = () => {
  let translateCoordinates = (code, line, column) => {
    let lines = Js.String.split("\n", code)

    let tilLine =
      lines
      ->Belt.Array.slice(~offset=0, ~len=line - 1)
      ->Belt.Array.joinWith("\n", s => s)
      ->Js.String.length

    tilLine + column + 1
  }

  linter(editor => {
    let code = contents(editor)

    let getModule = (definition: Script.definition) =>
      switch definition {
      | { it: Script.Textual(module_), _ } => module_
      | _ => assert(false)
      }

    let diagnostics =
      switch
        code
        ->Parse.string_to_module
        ->getModule
        ->Valid.check_module {
      | () => []
      | exception Valid.Invalid(at, message) => {
          let from = translateCoordinates(code, at.left.line, at.left.column)
          let to_ = translateCoordinates(code, at.right.line, at.right.column)
          [{ from, to_, severity: "error", message }]
        }
      | exception Parse.Syntax(at, message) => {
          let from = translateCoordinates(code, at.left.line, at.left.column)
          let to_ = translateCoordinates(code, at.right.line, at.right.column)
          [{ from, to_, severity: "error", message }]
        }
      }

    diagnostics
  }, { delay: Some(200) })
}

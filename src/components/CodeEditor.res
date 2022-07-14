open CodeMirror

@react.component
let make = (~state: React.ref<'a>, ~code: string, ~language: Language.t, ~extensions: array<extension>=[]) => {
  let inputRef = React.useRef(Js.Nullable.null)

  React.useEffect0(() => {
    let input =
      inputRef.current
      ->Js.Nullable.toOption
      ->Belt.Option.getExn

    switch state.current {
    | None => {
        let cm = make({
          doc: code,
          parent: input,
          extensions: Belt.Array.concat(
            [
              basicSetup,
              draculaTheme,
              Language.toExtension(language),
            ],
            extensions
          )
        })
        state.current = Some(cm)
      }
    | Some(_) => ()
    }


    None
  })

  <div className="h-full" ref={ReactDOM.Ref.domRef(inputRef)}></div>
}
@val external setTimeout : (unit => unit) => int => int = "setTimeout"
@val external clearTimeout : int => unit = "clearTimeout"

type state =
  | Initialiazing
  | Done
  | Fading

@react.component
let make = (~children, ~onClose) => {
  let (state, setState) = React.useState(() => Initialiazing)

  let close = () => {
    setState(_ => Fading)
    setTimeout(onClose, 500)
    ->ignore
  }

  React.useEffect1(() => {
    let closeHandle = setTimeout(close, 5000)
    let animationHandle = setTimeout(() => setState(_ => Done), 100)
    Some(() => {
      clearTimeout(closeHandle)
      clearTimeout(animationHandle)
    })
  }, [])

  let classes =
    switch state {
    | Initialiazing | Fading => "-right-full"
    | Done => "right-0"
    }

  <div className={"flex items-center absolute bg-gray-900 text-white p-4 rounded m-4 drop-shadow-lg transition-all " ++ classes}>
    <div className="flex flex-row items-center pr-8 pl-4">
      {children}
    </div>

    <button onClick={_ => close()}>
      <Icon.X />
    </button>
  </div>
}
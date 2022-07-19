let lineNumber = (. number, _) =>
  <p key={Belt.Int.toString(number)} className="py-1 pr-2 border-r-4 border-gray-500">
    {React.int(number + 1)}
  </p>

let action = (. dispatch) => (. idx, (label, fn)) =>
  <button key={Belt.Int.toString(idx)} className="float-right text-xs bg-deku-4 py-1 px-2 mx-1 rounded" onClick={_ => dispatch(fn())}>
    {React.string(label)}
  </button>

let logLine = (. dispatch) => (. idx, (line, actions)) =>
  <p key={Belt.Int.toString(idx)} className="text-white py-1 w-full">
    {React.string(line)}
    {actions->Belt.Array.mapWithIndexU(action(. dispatch))->React.array}
  </p>

@react.component
let make = (~log) => {
  let dispatch = State.useDispatch()

  <div className="font-mono text-sm flex flex-row h-full max-h-full overflow-scroll p-4">
    <div className="mr-4 text-right text-gray-400">
      {
        log
        ->Belt.Array.mapWithIndexU(lineNumber)
        ->React.array
      }
    </div>
    <div className="w-full">
      {
        log
        ->Belt.Array.mapWithIndexU(logLine(. dispatch))
        ->React.array
      }
    </div>
  </div>
}
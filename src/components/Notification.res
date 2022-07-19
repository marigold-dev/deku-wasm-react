@val external setTimeout : (unit => unit) => int => int = "setTimeout"
@val external clearTimeout : int => unit = "clearTimeout"

@react.component
let make = (~children, ~onClose) => {
  React.useEffect1(() => {
    let handle = setTimeout(onClose, 5000)
    Some(() => clearTimeout(handle))
  }, [])

  <div className="flex items-center absolute bg-gray-900 text-white p-4 rounded m-4 right-0 drop-shadow-lg">
    <div className="flex flex-row items-center pr-8 pl-4">
      {children}
    </div>

    <button onClick={_ => onClose()}>
      <Icon.X />
    </button>
  </div>
}
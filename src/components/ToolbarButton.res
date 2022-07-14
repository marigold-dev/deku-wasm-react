@react.component
let make = (~animate=false, ~icon, ~onClick) => {
  <button className="flex justify-center items-center bg-deku-2 h-12 w-12 m-2 rounded" onClick={_ => onClick()}>
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
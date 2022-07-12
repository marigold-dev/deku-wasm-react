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
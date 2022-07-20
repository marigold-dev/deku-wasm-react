@react.component
let make = (~title, ~animate=false, ~icon, ~onClick) => {
  <button
    title
    className="text-white flex justify-center items-center bg-deku-2 h-12 w-12 m-2 rounded hover:scale-105 transition-all hover:drop-shadow-lg"
    onClick={_ => onClick()}
  >
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
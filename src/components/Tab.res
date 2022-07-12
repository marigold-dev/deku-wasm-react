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
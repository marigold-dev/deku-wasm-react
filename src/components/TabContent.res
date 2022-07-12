@react.component
let make = (~currentTab, ~tab, ~children) => {
  let visibility = if currentTab == tab { "" } else { "hidden" }

  <div className={"contents h-full " ++ visibility}>
    {children}
  </div>
}
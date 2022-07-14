@react.component
let make = (~currentTab, ~tab, ~children) => {
  let visibility = if currentTab == tab { "" } else { "hidden" }

  <div className={"h-full max-h-full overflow-hidden " ++ visibility}>
    {children}
  </div>
}
module H1 = {
  @react.component
  let make = (~label) =>
    <h1 className="text-2xl font-medium mb-4">
      {React.string(label)}
    </h1>
}

module H2 = {
  @react.component
  let make = (~label) =>
    <h2 className="text-xl font-medium mb-4">
      {React.string(label)}
    </h2>
}

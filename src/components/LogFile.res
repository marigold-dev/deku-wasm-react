@react.component
let make = (~log) =>
  <div className="h-full max-h-full overflow-scroll p-4">
    {
      log
      ->Belt.Array.reverse
      ->Belt.Array.mapWithIndex((idx, entry) =>
          <p key={Belt.Int.toString(idx)} className="text-sm text-white py-1">
            {React.string(entry)}
          </p>
        )
      ->React.array
    }
  </div>
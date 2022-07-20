let renderItem = (~selected: bool, ~ticket_id: string, ~amount: int, ~onSelect: string => unit) => {
  <tr
    key={ticket_id}
    className={"cursor-pointer " ++ if selected {"bg-deku-1"} else {"hover:bg-deku-4"}}
    onClick={_ => onSelect(ticket_id)}
  >
    <td className="p-3">{React.string(ticket_id)}</td>
    <td className="p-3">{amount->Belt.Int.toString->React.string}</td>
  </tr>
}

@react.component
let make = (~tickets, ~onChange=?) => {
  let (selected, setSelected) = React.useState(_ => Belt.Set.String.empty)

  let onSelect = (ticket_id) => {
    setSelected(selected => {
      if Belt.Set.String.has(selected, ticket_id) {
        Belt.Set.String.remove(selected, ticket_id)
      } else {
        Belt.Set.String.add(selected, ticket_id)
      }
    })
  }

  React.useEffect1(() => {
    switch onChange {
    | Some(onChange) =>
      Js.Array.filter(
        ((ticket_id, _)) => Belt.Set.String.has(selected, ticket_id),
        tickets
      )
      ->onChange
    | None => ()
    }
    None
  }, [selected])

  let tickets =
    tickets
    ->Belt.Array.map (((ticket_id, amount)) =>
      renderItem(
        ~selected=Belt.Set.String.has(selected, ticket_id),
        ~ticket_id,
        ~amount,
        ~onSelect
    ))
    ->React.array

  <table className="text-white w-full my-4">
    <thead className="font-bold bg-deku-6">
      <tr>
        <td className="p-3">{React.string("Ticket ID")}</td>
        <td className="p-3">{React.string("Amount")}</td>
      </tr>
    </thead>
    <tbody>
      {tickets}
    </tbody>
  </table>
}
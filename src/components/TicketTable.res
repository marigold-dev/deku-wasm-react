let renderItem = (~ticket_id: string, ~amount: int) => {
  <tr>
    <td className="p-3">{React.string(ticket_id)}</td>
    <td className="p-3">{amount->Belt.Int.toString->React.string}</td>
  </tr>
}

@react.component
let make = (~tickets) => {
  let tickets =
    tickets
    ->Belt.Array.map (((ticket_id, amount)) => renderItem(~ticket_id, ~amount))
    ->React.array

  <table className="container text-white mx-auto my-4 mt-8">
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
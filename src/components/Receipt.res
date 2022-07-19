module ReceiptItem = {
  @react.component
  let make = (~name, ~value) => {
    <p className="flex justify-between py-2">
      <b>{React.string(name)}</b>
      <span>{React.string(value)}</span>
    </p>
  }
}

module ReceiptTicketTable = {
  @react.component
  let make = (~title, ~tickets) => {
    let ticket = ((ticket_id, amount)) =>
      <tr>
        <td>{React.string(ticket_id)}</td>
        <td className="text-right">{React.int(amount)}</td>
      </tr>

    <>
      <b className="block my-2 text-lg">{React.string(title)}</b>
      <table className="my-4 w-full text-sm">
        <thead className="font-semibold">
          <tr>
            <td>{React.string("TICKED ID")}</td>
            <td className="text-right">{React.string("AMOUNT")}</td>
          </tr>
        </thead>
        <tbody>
          {if Js.Array.length(tickets) == 0 {
            <p>{React.string("No tickets available")}</p>
          } else {
            tickets
            ->Belt.Array.map(ticket)
            ->React.array
          }}
        </tbody>
      </table>
    </>
  }
}

@react.component
let make = (~receipt: Deku.receipt) => {
  let dispatch = State.useDispatch()

  switch receipt {
  | Origination({ sender, outcome }) => {
      let outcome =
        switch outcome {
        | Success({ address, initialTickets }) => {
            <>
              <ReceiptItem name="Status" value="Success" />
              <ReceiptItem name="Contract address" value={address} />
              <ReceiptTicketTable title="Initial tickets" tickets=initialTickets />
            </>
          }
        | Failure => <ReceiptItem name="Status" value="Failure" />
        }

      <Modal title="Origination receipt" onClose={_ => dispatch(Action(CloseModal))}>
        <ReceiptItem name="Sender" value={sender} />
        {outcome}
      </Modal>
    }
  | Invocation({ sender, outcome }) => {
      let outcome =
        switch outcome {
        | Success({ remainingTickets, newStorage }) =>
            <>
              <ReceiptItem name="Status" value="Success" />
              <ReceiptItem name="New storage" value={Js.Json.stringifyAny(newStorage)->Belt.Option.getExn} />
              <ReceiptTicketTable title="Remaining tickets" tickets=remainingTickets />
            </>
        | Failure => <ReceiptItem name="Status" value="Failure" />
        }

      <Modal title="Invocation receipt" onClose={_ => dispatch(Action(CloseModal))}>
        <ReceiptItem name="Sender" value=sender />
        {outcome}
      </Modal>
    }
  }
}
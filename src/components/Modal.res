
@react.component
let make = (~title, ~children, ~onClose) => {
  <div className="flex justify-center items-center bg-gray-700/[.7] absolute w-full h-full z-50">
    <div className="basis-1/2 h-1/2 text-white bg-gray-800 rounded p-6">
      <header className="flex justify-between items-start">
        <Title.H2 label=title />

        <button onClick={_ => onClose()}>
          <Icon.X />
        </button>
      </header>

      <main>
        {children}
      </main>
    </div>
  </div>
}
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./pages/**/*.{js,ts,jsx,tsx}",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        'deku-1': '#7B7FC7',
        'deku-2': '#7477BB',
        'deku-3': '#575989',
        'deku-4': '#424366',
        'deku-5': '#24253B',
        'deku-6': '#0D0E18'
      }
    },
  },
  plugins: [],
}

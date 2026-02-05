/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./app/views/**/*.html.erb",
    "./app/helpers/**/*.rb",
    "./app/javascript/**/*.js"
  ],
  safelist: [
    "bg-gradient-to-br",
    "from-purple-50",
    "via-fuchsia-50",
    "to-indigo-50"
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}

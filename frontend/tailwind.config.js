/** @type {import('tailwindcss').Config} */
module.exports = {
    content: ["./src/**/*.{html,js}", "./components/**/*.{js,jsx,ts,tsx}"],
    theme: {
        extend: {
            fontFamily: {
                montserrat: ["var(--font-montserrat)"],
            },
            colors: {
                "gray-dark": "#3D3D3E",
                "gray-black": "#2D2D2E",
                ochre: "#A06D22",
            },
        },
    },
    plugins: [],
}

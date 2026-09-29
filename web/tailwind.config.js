/** @type {import('tailwindcss').Config} */
export default {
  darkMode: ["class"],
  content: ["./index.html", "./src/**/*.{js,jsx}"],
  theme: {
    extend: {
      colors: {
        brand: {
          50: "#eff6ff",
          100: "#dbeafe",
          500: "#3b82f6",
          600: "#2563eb",
          700: "#1d4ed8",
          800: "#1e40af",
          900: "#1e3a8a",
          950: "#0f1e3d"
        }
      },
      boxShadow: {
        soft: "0 1px 2px rgba(15,23,42,.04),0 8px 24px rgba(15,23,42,.06)"
      }
    }
  },
  plugins: []
};

/** @type {import('tailwindcss').Config} */
export default {
  darkMode: ["class"],
  content: ["./index.html", "./src/**/*.{js,jsx}"],
  theme: {
    extend: {
      colors: {
        brand: {
          50: "#fff1f0",
          100: "#ffe0dd",
          400: "#ff756a",
          500: "#ff5b50",
          600: "#ed4d44",
          700: "#c93532",
          800: "#9f2a2b",
          900: "#762428",
          950: "#2c0d10"
        }
      },
      boxShadow: {
        soft: "0 18px 45px rgba(0,0,0,.20)",
        glass: "inset 0 1px 0 rgba(255,255,255,.04), 0 18px 45px rgba(0,0,0,.22)",
        glow: "0 12px 34px rgba(226,67,59,.18)"
      },
      animation: {
        "fade-up": "fadeUp .45s cubic-bezier(.2,.8,.2,1) both",
        "soft-pulse": "softPulse 2.6s ease-in-out infinite"
      },
      keyframes: {
        fadeUp: {
          "0%": { opacity: "0", transform: "translateY(10px)" },
          "100%": { opacity: "1", transform: "translateY(0)" }
        },
        softPulse: {
          "0%,100%": { opacity: ".55" },
          "50%": { opacity: "1" }
        }
      }
    }
  },
  plugins: []
};

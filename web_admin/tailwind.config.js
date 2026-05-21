/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
    './node_modules/@tremor/**/*.{js,ts,jsx,tsx}',
  ],
  theme: {
    extend: {
      colors: {
        brand: {
          50:  '#f3f1ff',
          100: '#eae7ff',
          200: '#d5cfff',
          300: '#b9aeff',
          400: '#9b8dff',
          500: '#7b6eff',
          600: '#6c63ff',
          700: '#5b52e0',
          800: '#4a43bd',
          900: '#363299',
          950: '#201e66',
        },
        /* forest aliased to brand so all existing pages keep working */
        forest: {
          50:  '#f3f1ff',
          100: '#eae7ff',
          200: '#d5cfff',
          300: '#b9aeff',
          400: '#9b8dff',
          500: '#7b6eff',
          600: '#6c63ff',
          700: '#5b52e0',
          800: '#6c63ff',
          900: '#5b52e0',
          950: '#201e66',
        },
      },
      fontFamily: { sans: ['Inter', 'sans-serif'] },
      boxShadow: {
        'card':    '0 1px 3px 0 rgb(0 0 0 / .06), 0 1px 2px -1px rgb(0 0 0 / .04)',
        'card-md': '0 4px 16px -2px rgb(0 0 0 / .10), 0 2px 6px -2px rgb(0 0 0 / .06)',
        'card-lg': '0 12px 32px -4px rgb(0 0 0 / .14), 0 4px 12px -4px rgb(0 0 0 / .08)',
      },
      animation: {
        'fade-up':   'fadeUp .3s ease both',
        'fade-in':   'fadeIn .25s ease both',
        'pulse-dot': 'pulseDot 2s ease-in-out infinite',
      },
      keyframes: {
        fadeUp:   { from: { opacity: '0', transform: 'translateY(10px)' }, to: { opacity: '1', transform: 'none' } },
        fadeIn:   { from: { opacity: '0' }, to: { opacity: '1' } },
        pulseDot: { '0%,100%': { opacity: '1' }, '50%': { opacity: '.35' } },
      },
    },
  },
  plugins: [],
}

# 🌀 useScrollToComponent – Smooth Scrolling React Hook

A powerful, flexible React + TypeScript hook that scrolls to any element on the page with smooth animation, customizable offset, and optional callback support.

---

## 🚀 Features

- 🔎 Scroll to any **DOM element**, by `id`, class, selector, or reference.
- 💨 Supports **smooth** and **auto** scroll behavior.
- 🎯 Optional **offset** to account for fixed headers.
- 🧠 Skips scrolling if the element is already in view (optional).
- 🪝 Runs a **callback** when scroll completes.
- ✅ Written in **TypeScript** for safety and autocompletion.

---

## 📦 Installation

Copy the `useScrollToComponent.ts` file into your project:

// useScrollToComponent.ts

No external dependencies required.

---

## 🧩 Hook API

### `useScrollToComponent() => scrollToComponent`

Returns a function that can scroll to a given element with options.

---

### 📌 Usage

```tsx
const scrollToComponent = useScrollToComponent();

scrollToComponent('#target', {
  offset: 100,
  behavior: 'smooth',
  callback: () => console.log('Scroll finished!'),
  skipIfVisible: true,
});
```

## 🔧 Parameters
`target` (string | HTMLElement)

- The element to scroll to.
- Can be a selector (e.g., `#id`, `.class`, `div > section`) or a real `HTMLElement`.

| Option          | Type                 | Default     | Description                                              |
| --------------- | -------------------- | ----------- | -------------------------------------------------------- |
| `offset`        | `number`             | `0`         | Pixels to offset from the top (e.g., for fixed headers). |
| `behavior`      | `'smooth' \| 'auto'` | `'smooth'`  | Scrolling behavior.                                      |
| `callback`      | `() => void`         | `undefined` | Function to call when scrolling finishes.                |
| `skipIfVisible` | `boolean`            | `false`     | Prevent scrolling if the element is already in view.     |

## 🧼 Cleanup / Notes

- The hook uses `IntersectionObserver` to detect when scrolling completes (only for `'smooth'` behavior).
- For immediate scroll (`'auto'`), the callback is called instantly.

## 🛠 Future Improvements (`PRs welcome!`)

- Support horizontal scrolling (scrollX).
- Allow scroll duration customization.
- Fallback support for older browsers.

## 📝License [MIT LICENCE]()
## 🙌 Contributing

Feel free to open issues or submit PRs to improve the hook or documentation.

### 💻 Author
#### Made with ❤️ by [Harsh Yadav](https://github.com/HarshYadav152)

## 🔧 How to Use It
#### ✅ Scroll by selector:
```js
scrollToComponent('#my-section', {
  offset: 100,
  behavior: 'smooth',
  callback: () => console.log('Arrived!'),
});
```
### ✅ Scroll by DOM element:
```js
const section = document.querySelector('section');
scrollToComponent(section, { offset: 50 });
```

### ✅ Skip scroll if already in view:
```js
scrollToComponent('#footer', {
  skipIfVisible: true,
});
```

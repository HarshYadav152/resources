/**
 * Scrolls to a DOM element with smooth animation and optional offset
 * @param target - CSS selector string (e.g. '#myId', '.myClass') or HTMLElement
 * @param options - Optional configuration for scrolling
 */
export function scrollToComponent(
  target: string | HTMLElement,
  options: {
    offset?: number;
    behavior?: ScrollBehavior;
    callback?: () => void;
    skipIfVisible?: boolean;
  } = {}
): void {
  const {
    offset = 0,
    behavior = 'smooth',
    callback,
    skipIfVisible = false,
  } = options;

  let element: HTMLElement | null = null;

  if (typeof target === 'string') {
    element = document.querySelector(target);
  } else if (target instanceof HTMLElement) {
    element = target;
  }

  if (!element) {
    console.warn('Element not found:', target);
    return;
  }

  const isInViewport = () => {
    const rect = element!.getBoundingClientRect();
    return rect.top >= 0 && rect.bottom <= window.innerHeight;
  };

  if (skipIfVisible && isInViewport()) {
    console.log('Element already in view:', element);
    callback?.();
    return;
  }

  const elementPosition = element.getBoundingClientRect().top;
  const offsetPosition = elementPosition + window.pageYOffset - offset;

  window.scrollTo({
    top: offsetPosition,
    behavior,
  });

  if (typeof callback === 'function') {
    if (behavior === 'auto') {
      callback();
    } else {
      const observer = new IntersectionObserver(
        (entries, obs) => {
          if (entries[0].isIntersecting) {
            callback();
            obs.disconnect();
          }
        },
        { threshold: 0.6 }
      );

      observer.observe(element);
    }
  }

  console.log('Scrolled to element:', element);
}

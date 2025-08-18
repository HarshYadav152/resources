// useScrollToComponent.ts
import { useCallback } from 'react';

type ScrollBehavior = 'auto' | 'smooth';

interface ScrollOptions {
  offset?: number;
  behavior?: ScrollBehavior;
  callback?: () => void;
  skipIfVisible?: boolean;
}

export const useScrollToComponent = () => {
  const scrollToComponent = useCallback(
    (
      target: string | HTMLElement,
      {
        offset = 0,
        behavior = 'smooth',
        callback,
        skipIfVisible = false,
      }: ScrollOptions = {}
    ) => {
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
        console.log('Element already in view, skipping scroll:', element);
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
          // Best-effort smooth scroll finish detection
          const observer = new IntersectionObserver(
            (entries, obs) => {
              const entry = entries[0];
              if (entry.isIntersecting) {
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
    },
    []
  );

  return scrollToComponent;
};

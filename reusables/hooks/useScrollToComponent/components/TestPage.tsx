import React from 'react';
import { useScrollToComponent } from '../useScrollToComponent';

const TestPage = () => {
  const scrollToComponent = useScrollToComponent();

  const handleClick = () => {
    scrollToComponent('#target-section', {
      offset: 80,
      behavior: 'smooth',
      skipIfVisible: true,
      callback: () => {
        console.log('Scroll complete!');
      },
    });
  };

  return (
    <>
      <button onClick={handleClick}>Scroll to Section</button>

      <div style={{ height: '1500px' }}></div>

      <div id="target-section" style={{ height: '300px', background: 'lightblue' }}>
        Target Section
      </div>
    </>
  );
};

export default TestPage;

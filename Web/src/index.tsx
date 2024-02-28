import React from 'react';
import ReactDOM from 'react-dom/client';
import './index.css';
import App from './App';
import { FluentProvider, teamsDarkTheme } from '@fluentui/react-components';

const root = ReactDOM.createRoot(
  document.getElementById('root') as HTMLElement
);
root.render(
  <React.StrictMode>
    <FluentProvider theme={teamsDarkTheme} style={{height: "100%"}}>
      <App />
    </FluentProvider>
  </React.StrictMode>
);

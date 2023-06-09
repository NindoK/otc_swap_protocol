// store.js
import { createStore } from 'redux';
import { Provider } from 'react-redux';

// Define your initial state and reducers
const initialState = {
  data: null,
};

function rootReducer(state = initialState, action) {
  switch (action.type) {
    case 'SET_DATA':
      return {
        ...state,
        data: action.payload,
      };
    default:
      return state;
  }
}

const store = createStore(rootReducer);

export default function ReduxProvider({ children }) {
  return <Provider store={store}>{children}</Provider>;
}

import React from 'react'

const Button = ({styles}) => {
  return (
    <button type="button" className={`py-4 px-6 font-montserrat font-medium text-[18px] text-gray-700 bg-blue-gradient rounded-[10px] outline-none ${styles}`}>
    Get Started
  </button>
  )
}

export default Button
"use client"
import { CardData } from '@components/CardData'
import Sidebar from '@components/Sidebar'
import TakeDealCard from '@components/TakeDealCard'
import React, { useState } from 'react'

const page = () => {
    const [searchTerm, setSearchTerm] = useState('');

    // Filter the cards based on the search term
    const filteredCards = CardData.filter((card) => {
        return card.dealId.toString().includes(searchTerm);
    });
  return (
    <div className="flex min-h-fit h-screen w-full bg-black">
    {/* gradient start */}
    <div className="absolute z-[0] w-[40%] h-[35%] top-0 right-0 pink__gradient" />
    <div className="absolute z-[0] w-[40%] h-[50%] rounded-full right-0 white__gradient bottom-40" />
    <div className="absolute z-[0] w-[50%] h-[50%] left-0 bottom-40 blue__gradient" />
    {/* gradient end */}
            <Sidebar />

           <div className='w-full flex flex-col '>
           <div className=" w-full flex justify-start">
           <input
             type="text"
             placeholder="Search by ID"
             className="p-2 border border-gray-300 bg-gray-black rounded mt-10 ml-40 text-gray-400"
             value={searchTerm}
             onChange={(e) => setSearchTerm(e.target.value)}
           />
         </div>
   
               <ul className="mt-6 ml-40 flex flex-row gap-5 flex-wrap">
                   {filteredCards.map((val, key) => {
                       return (
                           <li>
                               <TakeDealCard
                                   key={key}
                                   id={val.dealId}
                                   underlyingtoken={val.underlyingtoken}
                                   quotetoken={val.quotetoken}
                                   strike={val.strike}
                                   maturity={val.maturity}
                                   optioncall={val.optioncall}
                                   amount={val.amount}
                                   premium={val.premium}
                                   status={val.status}
                                   buyer={val.buyer}
                                   seller={val.seller}
                               />
                           </li>
                       )
                   })}
               </ul>
           </div>
   </div>


  )
}

export default page
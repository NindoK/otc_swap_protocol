import React from "react"
import styles from "@src/app/style"
import person1 from "@public/person1.png"
import person2 from "@public/person2.jpeg"
import person4 from "@public/person4.png"
import person3 from "@public/person3.jpeg"
import Image from "next/image"
export const feedback = [
    {
        id: "feedback-1",

        name: "Nindo K",
        title: "Developer",
        img: person1,
    },
    {
        id: "feedback-2",

        name: "Aliroody",
        title: "Developer",
        img: person2,
    },
    {
        id: "feedback-3",

        name: "Sakshi Shah",
        title: "Developer",
        img: person3,
    },
    {
        id: "feedback-4",
        name: "Quantoor",
        title: "Developer",
        img: person4,
    },
]
const FeedbackCard = ({ name, title, img }) => (
    <div className="flex justify-between items-center flex-col px-5 py-5 rounded-[20px]  max-w-[370px] md:mr-10 sm:mr-5 mr-0 my-5 feedback-card">
        <Image src={img} alt={name} className="w-[48px] h-[48px] rounded-full" />
        <div className="flex flex-col ml-4">
            <h4 className=" font-montserrat font-semibold text-[20px] leading-[32px] text-white text-center">
                {name}
            </h4>
            <p className=" font-montserrat font-normal text-[16px] leading-[24px] text-gray-500 text-center">
                {title}
            </p>
        </div>
    </div>
)

const Devs = () => {
    return (
        <section
            id="clients"
            className={`${styles.paddingY} ${styles.flexCenter} flex-col relative `}
        >
            <div className="absolute z-[0] w-[70%] h-[100%] -right-[50%] rounded-full blue__gradient bottom-40" />

            <div className="w-full flex justify-between items-center md:flex-row flex-col sm:mb-16 mb-6 relative z-[1]">
                <h2 className="text-gradient font-montserrat font-semibold xs:text-[48px] text-[40px] xs:leading-[76.8px] leading-[66.8px] w-full text-center">
                    Meet the Developers
                </h2>
            </div>

            <div className="flex lg:gap-28 lg:pl-20 flex-wrap sm:justify-start justify-center w-full feedback-container relative z-[1]">
                {feedback.map((card) => (
                    <FeedbackCard key={card.id} {...card} />
                ))}
            </div>
        </section>
    )
}

export default Devs

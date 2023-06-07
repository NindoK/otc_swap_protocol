import React from "react"
import styles, { layout } from "@src/app/style"
import Button from "./Button"
import star from "@public/Star.svg"
import shield from "@public/Shield.svg"
import send from "@public/Send.svg"
import Image from "next/image"

export const features = [
    {
        id: "feature-1",
        icon: star,
        title: "Lorem Ipsum",
        content: "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
    },
    {
        id: "feature-2",
        icon: shield,
        title: "Lorem Ipsum",
        content: "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
    },
    {
        id: "feature-3",
        icon: send,
        title: "Lorem Ipsum",
        content: "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
    },
]

const FeatureCard = ({ icon, title, content, index }) => (
    <div
        className={`flex flex-row p-6 rounded-[20px] ${
            index !== features.length - 1 ? "mb-6" : "mb-0"
        } feature-card cursor-pointer`}
    >
        <div className={`w-[64px] h-[64px] rounded-full ${styles.flexCenter} bg-dimBlue`}>
            <Image src={icon} alt="star" className="w-[50%] h-[50%] object-contain" />
        </div>
        <div className="flex-1 flex flex-col ml-3">
            <h4 className="font-montserrat font-semibold text-white text-[18px] leading-[23.4px] mb-1">
                {title}
            </h4>
            <p className="font-montserrat font-normal text-gray-500 text-[16px] leading-[24px]">
                {content}
            </p>
        </div>
    </div>
)

const Feature1 = () => {
    return (
        <section id="features" className={`${layout.section} lg:pl-24`}>
            <div className={layout.sectionInfo}>
                <h2 className={styles.heading2}>
                    Lorem ipsum dolor sit, <br className="sm:block hidden" /> consectetur adipiscing
                    elit.
                </h2>
                <p className={`${styles.paragraph} max-w-[470px] mt-5`}>
                    Lorem ipsum dolor sit amet, consectetur adipiscing elit. Integer volutpat
                    consectetur risus, id consectetur sem dictum quis. Nullam vulputate placerat
                    mauris, vitae ultrices quam. Praesent malesuada nisi nec nibh pulvinar
                    dignissim.
                </p>

                <Button styles={`mt-10`} />
            </div>

            <div className={`${layout.sectionImg} flex-col`}>
                {features.map((feature, index) => (
                    <FeatureCard key={feature.id} {...feature} index={index} />
                ))}
            </div>
        </section>
    )
}

export default Feature1

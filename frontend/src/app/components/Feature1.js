import React from 'react'
import styles,{layout} from '../style';
import Button from './Button';
const FeatureCard = ({ index }) => (
    <div className={`flex flex-row p-6 rounded-[20px] mb-6 feature-card`}>
      
      <div className="flex-1 flex flex-col ml-3">
        <h4 className="font-poppins font-semibold text-white text-[18px] leading-[23.4px] mb-1">
          lorem Ipsum
        </h4>
        <p className="font-poppins font-normal text-dimWhite text-[16px] leading-[24px]">
          lorem ipsum lorem ipsum lorem ipsum lorem ipsum
        </p>
      </div>
    </div>
  );

const Feature1 = () => {
  return (
    <section id="features" className={`flex justify-center items-center lg:mx-28`}>
    <div className={`${layout.sectionInfo}`}>
      <h2 className={`${styles.heading2}`}>
        You do the business, <br className="sm:block hidden" /> we’ll handle
        the money.
      </h2>
      <p className={`${styles.paragraph} max-w-[470px] mt-5`}>
        With the right credit card, you can improve your financial life by
        building credit, earning rewards and saving money. But with hundreds
        of credit cards on the market.
      </p>

      <Button styles={`mt-10`} />
    </div>

    <div className={`${layout.sectionImg} flex-col`}>
      <FeatureCard/>
      <FeatureCard/>
      <FeatureCard/>
    </div>
  </section>
  )
}

export default Feature1
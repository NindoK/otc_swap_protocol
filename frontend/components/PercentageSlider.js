"use client"
import { Box, Slider, SliderFilledTrack, SliderThumb, SliderTrack, Text } from "@chakra-ui/react"
import React, { useState } from "react"

const PercentageSlider = ({ setPriceMultiplier }) => {
    const [value, setValue] = useState(100)

    const handleSliderChange = (newValue) => {
        setValue(newValue)
        setPriceMultiplier(newValue)
    }

    return (
        <Box width="300px">
            <Slider
                min={0}
                max={300}
                step={1}
                value={value}
                onChange={handleSliderChange}
                aria-label="Percentage Slider"
            >
                <SliderTrack>
                    <SliderFilledTrack />
                </SliderTrack>
                <SliderThumb fontSize="sm" boxSize="20px">
                    {value > 0 ? <Text>+</Text> : value < 0 ? <Text>-</Text> : <Text>&nbsp;</Text>}
                    {Math.abs(value)}%
                </SliderThumb>
            </Slider>
            {value > 100 ? (
                <Text color="green" mt={2}>
                    Premium +{value}%
                </Text>
            ) : value < 100 ? (
                <Text color="red" mt={2}>
                    Discount {value}%
                </Text>
            ) : null}
        </Box>
    )
}

export default PercentageSlider

import { Box, Flex, Select, Tag, TagCloseButton, TagLabel } from "@chakra-ui/react"
import axios from "axios"
import React, { useEffect, useState } from "react"

const MultipleTags = ({ setTokensAccepted }) => {
    const [inputValue, setInputValue] = useState("")
    const [tags, setTags] = useState([])
    const [tokenData, setTokenData] = useState([])

    async function fetchTokenData() {
        try {
            const response = await axios.get("https://tokens.coingecko.com/uniswap/all.json")
            const tokens = response.data.tokens

            setTokenData(tokens)
        } catch (error) {
            console.error("Error fetching token data:", error)
        }
    }

    useEffect(() => {
        fetchTokenData()
    }, [])

    const handleInputChange = (event) => {
        setInputValue(event.target.value)
    }

    const handleInputKeyDown = (event) => {
        if (event.key === "Enter" && inputValue.trim() !== "") {
            setTags([...tags, inputValue.trim()])
            setTokensAccepted([...tags, inputValue.trim()])
            setInputValue("")
        }
    }

    const handleRemoveTag = (tag) => {
        const updatedTags = tags.filter((t) => t !== tag)
        setTags(updatedTags)
    }
    return (
        <Flex direction="column" width="300px">
            <Box mb={2}>
                {tags.map((tag, index) => (
                    <Tag key={`${tag}-${index}`} size="md" mr={1} mb={1}>
                        <TagLabel>{tag}</TagLabel>
                        <TagCloseButton onClick={() => handleRemoveTag(tag)} />
                    </Tag>
                ))}
            </Box>

            <Select
                placeholder="Select options"
                isMulti
                size="md"
                value={inputValue}
                onChange={handleInputChange}
                onKeyDown={handleInputKeyDown}
                mt={2}
            >
                {tokenData.slice(0, 20).map((token) => (
                    <option key={`${token.name}-${token.symbol}`} value={token.address}>
                        {token.symbol}
                    </option>
                ))}
            </Select>
        </Flex>
    )
}

export default MultipleTags

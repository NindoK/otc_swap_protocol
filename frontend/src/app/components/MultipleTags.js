import { Box, Flex, Select, Tag, TagCloseButton, TagLabel } from '@chakra-ui/react'
import axios from 'axios'
import React, { useEffect, useState } from 'react'

const MultipleTags = () => {

    
    const [selectedOptions, setSelectedOptions] = useState([])
    const [inputValue, setInputValue] = useState("")
    const [tags, setTags] = useState([]);
    const [tokenData,setTokenData]=useState([]);
    const [value, setValue] = React.useState("0")

    async function fetchTokenData() {
        try {
            const response = await axios.get(
                "https://api.coingecko.com/api/v3/exchanges/uniswap_v2/tickers"
            )

            // Process the response data
            const tokens = response.data.tickers.slice(0, 20)
            console.log(tokens)
            console.log(tokens.map((token) => token.coin_id))
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
        {tags.map((tag) => (
            <Tag key={tag} size="md" mr={1} mb={1}>
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
    {tokenData.map((token) => (
        <option key={token.coin_id}>{token.coin_id}</option>
    ))}
    </Select>
</Flex>
  )
}

export default MultipleTags
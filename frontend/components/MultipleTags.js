import { AddIcon } from "@chakra-ui/icons"
import { Box, Flex, IconButton, Select, Tag, TagCloseButton, TagLabel } from "@chakra-ui/react"
import axios from "axios"
import React, { useEffect, useState } from "react"

const MultipleTags = ({ tokensAccepted, setTokensAccepted }) => {
    const [inputValue, setInputValue] = useState("")
    const [tags, setTags] = useState([])
    const [tokenData, setTokenData] = useState([])

    async function fetchTokenData() {
        try {
            const response = await axios.get(
                "https://api.coingecko.com/api/v3/exchanges/uniswap_v2/tickers"
            )

            // Process the response data
            const tokens = response.data.tickers
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
          addTag();
        }
      };

      const handleAddTag = () => {
        if (inputValue.trim() !== "") {
          addTag();
        }
      };
    
      const addTag = () => {
        const trimmedValue = inputValue.trim();
        // Check if the tag already exists
        if (!tags.includes(trimmedValue)) {
          setTags([...tags, trimmedValue]);
        }
        setInputValue("");
      };

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
                    <option key={`${token.coin_id}-${token.target_coin_id}`} value={token.base}>
                        {token.coin_id}
                        <IconButton
              aria-label="Add Tag"
              icon={<AddIcon />}
              size="sm"
              variant="ghost"
              colorScheme="green"
              onClick={() => handleAddTag(token.coin_id)}
              ml={2}
            />
                    </option>
                ))}
            </Select>

            <button
        onClick={handleAddTag}
        disabled={inputValue.trim() === ""}
        style={{
          marginTop: "5px",
          backgroundColor: "green",
          color: "white",
          margin: "5px 120px",
          border: "none",
          borderRadius: "50px",
          cursor: "pointer",
        }}
      >
        +
      </button>
        </Flex>
    )
}

export default MultipleTags

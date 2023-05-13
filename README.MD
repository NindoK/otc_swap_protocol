# OTC SWAP PROTOCOL

## Prerequisites
Current setup used:
```
forge 0.2.0
solc 0.8.17+commit.8df45f5f.Darwin.appleclang
Node.js 16.14.2
npm 8.15.0
yarn 1.22.19
```

## Installation
Clone the repository:
```
https://github.com/NindoK/otc_swap_protocol.git
cd otc_swap_protocol
```

## Install dependencies:

```
forge install
```

Now in `lib/` all the required packages should be available.

### ENV file

Run the following:
```
mv .env.example .env
```

## Run Tests

To run tests:

```
forge test
```

To check code coverage:

```
forge coverage
```
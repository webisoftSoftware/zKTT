# Zero Knowledge Table Top

## Running Locally

#### Terminal one (Make sure this is running)

```bash
# Run Katana
katana --disable-fee --allowed-origins "*"
```

#### Terminal two

```bash
# Build the example
sozo build

# Migrate the example
sozo migrate apply

# Start Torii
torii --world 0x3b34889efbdf01f707d5d7421f112e8fb85a42fb6f2e5422c75ce3253148b0e --allowed-origins "*"
```

---

[![CI](https://github.com/webisoftSoftware/zktt/actions/workflows/test.yaml/badge.svg)](https://github.com/webisoftSoftware/zktt/actions/workflows/test.yaml)


<a href="https://zktable.top"><img src="assets/zktt_transparent.png" alt="zkTT logo" style="width:400px;"></a>

# zKTT - Cairo Contracts
### Running Locally


---

#### Terminal one (Make sure this is running)

```bash
# Run Katana
katana --disable-fee --allowed-origins "*"
```

#### Terminal two (Make sure this is running)

```bash
# Start Torii
torii --world <world-hash> --allowed-origins "*"
```

#### Terminal three
```bash
# Build the contracts
sozo build

# Load models and systems onto katana.
sozo migrate apply

# Join with two different example accounts.
./join.sh

# Interact with the world and the systems.

## Without call data:
sozo execute table <system-name> (i.e start)

## With call data:
sozo execute table <system-name> (i.e start) -c [...params deserialized]

# Example (with call data):
sozo execute table play -c 0,<owner_addr>,str:<asset_name>,<value>,<copies_left>
```

---

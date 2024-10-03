<a href="https://zktable.top"><img src="assets/zktt_transparent.png" alt="zkTT logo" style="width:400px;"></a>

# zKTT - Cairo Contracts
### Running Locally


---

#### Terminal one (Make sure this is running)

```bash
# Run Katana
katana --disable-fee --allowed-origins "*"
```

#### Terminal two

```bash
# Build the contracts
sozo build

# Load models and systems onto katana.
sozo migrate apply

# Authorize writing of components.
./auth.sh

# Join with two example accounts.
./join.sh

# Interact with the world and the systems.
sozo execute --world <world-hash> table <system-name> (i.e start)
```

#### Terminal three
```bash
# Start Torii
torii --world <world-hash> --allowed-origins "*"
```

---

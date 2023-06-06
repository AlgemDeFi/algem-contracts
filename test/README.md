# Requirements

All tests are performed on
```
./astar-collator --dev
```
which may be obtained [here](https://github.com/AstarNetwork/Astar/releases).

Also you may want to build your own astar collator with different core [values](https://github.com/AstarNetwork/Astar/blob/411b250c49bccf5b6eb9953f7d0718c33065a3e9/runtime/local/src/lib.rs#L361).

# Chain

Run

```
yarn chain
```

if you have astar-collator binary at project root.

Or run it manually as shown in first section.

# Tests

```
yarn test
```

Or

```
npx hardhat test --network astarLocal
```

# Known issues

You have to clean .openzeppelin/unknown-4369.json if you get ```removed from manifest``` error.

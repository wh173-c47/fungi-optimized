## Fungi

## Initiate project

Once pulled, you can run the below commands to make sure all deps are setup

```shell
forge install foundry-rs/forge-std --no-commit
forge install vectorized/solady --no-commit
```

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Deploy

```shell
$ forge script script/Fungi.s.sol:FungiScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

# Dss Add Ilk Spell

Spell contract to deploy a new collateral type (TBTC) in the DSS system.

## Resources

 - [ds-chief](https://github.com/dapphub/ds-chief/blob/master/src/chief.sol) and [doc](https://docs.makerdao.com/smart-contract-modules/governance-module/chief-detailed-documentation)
 - [pause](https://docs.makerdao.com/smart-contract-modules/governance-module/pause-detailed-documentation#2-contract-details), relevant for `Spell.schedule/cast`
 - dapptool's [seth](https://github.com/dapphub/dapptools)


### Steps:

Clone the repo. 

```sh
git clone https://github.com/keep-network/tbtc-makerdao-mcd --recursive --quiet
```

#### Install Nix + Dapptools
Dapptools is the MakerDAO toolset for Ethereum transactions. We need to install an older version, as the newer one is broken (see [this issue](https://github.com/dapphub/dapptools/issues/341) for more).

For ease of setup, we'll install Dapptools-latest and then proceed to rebuild an older version.

```sh
curl https://dapp.tools/install | sh
```

Now Nix + dapptools should be installed, let's install the older (working) version.

```
cd dapptools/
git submodule update --init --remote --quiet
nix-env -f . -iA dapp seth solc hevm ethsign
```

It should be installed. Test by running `which seth`, and if after reloading your terminal it fails, add `. $HOME/.nix-profile/etc/profile.d/nix.sh` to your profile.

### Run

There are scripts which automate the majority of the steps found in the [original guide](https://github.com/keep-network/tbtc-makerdao-mcd/blob/d41459d7e1646fe9517bba00c411c7d6f2201187/README.md).

Note: scripts are configured to use Ropsten by default, though with some find+replace you can configure Kovan too.

1) Run `source account.sh` to configure a Ropsten account preloaded with Ether, and some environment variables for Dapptools. 

2) Compile the spell contracts.

-  ```sh
   dapp update
   dapp build --extract
   ```

3) Deploy the spell and slate it for voting. This should output the spell contract address. We'll need to store this into `$SPELL` afterwards.

- `./1-deploy-spell.sh`

4) Wait for the Spell to be elected. This is where your friendly neighbourhood MKR whale can help. 😉

5) Schedule Spell, Wait for Pause delay (0 on Ropsten, 5 minutes on mainnet), Cast Spell

- `./2-cast-spell.sh $SPELL`
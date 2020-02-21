set -ex

# Set accounts.
source account.sh

export ETH_GAS=3000000

# Setup contract addresses.
# 

for MAKER_CONTRACT in $(cat deployments/maker_rinkeby.json| jq -r 'keys[]')
do
    ADDRESS=$(cat deployments/maker_rinkeby.json | jq -r .$MAKER_CONTRACT)
    export $MAKER_CONTRACT=$ADDRESS
done

# We load these programatically above.
# export MCD_VAT=0xba987bdb501d131f766fee8180da5d81b34b69d9
# export MCD_CAT=0x0511674a67192fe51e86fe55ed660eb4f995bdd6
# export MCD_JUG=0xcbb7718c9f39d05aeede1c472ca8bf804b2f1ead
# export MCD_SPOT=0x3a042de6413edb15f2784f2f97cc68c7e9750b2d
# export MCD_PAUSE=0x8754e6ecb4fe68daa5132c2886ab39297a5c7189
# export MCD_PAUSE_PROXY=0x0e4725db88bb038bba4c4723e91ba183be11edf3
# export MCD_ADM=0xbbffc76e94b34f72d96d054b31f6424249c1337d
# export MCD_END=0x24728acf2e2c403f5d2db4df6834b8998e56aa5f
# export MCD_JOIN_DAI=0x5aa71a3ae1c0bd6ac27a1f28e1415fffb6f15b8c


# TBTC Token
export TOKEN="0x083f652051b9CdBf65735f98d83cc329725Aa957"


# Set Collateral Type.
# Each ethereum token in Maker Protocol can have multiple collateral types and each one can be initialized with a different set of risk parameters. 
# Affixing an alphabetical letter to the token symbol will help users differentiate these collateral types.
export ILK="$(seth --to-bytes32 "$(seth --from-ascii "TBTC-A")")"


# A set of changes to be made at a time are captured in a Spell smart contract. 
# Once a Spell is deployed, governance can elect its address as an authority which then lets it execute the changes in Maker Protocol. 
# Although it is strictly not required, spells currently are designed to be used once and will lock up after they are executed.


# Deploy price feeds.
export PIP=$(dapp create DSValue)
seth send $PIP 'poke(bytes32)' $(seth --to-uint256 "$(seth --to-wei 9000 ETH)")

echo TBTC price set to $(seth call $PIP 'read()')

export JOIN=$(dapp create GemJoin "$MCD_VAT" "$ILK" "$TOKEN")

# Deploy Collateral Auction contract.
export FLIP=$(dapp create Flipper "$MCD_VAT" "$ILK")
seth send "$FLIP" 'rely(address)' "$MCD_PAUSE_PROXY"
seth send "$FLIP" 'deny(address)' "$ETH_FROM"


# Calculate Risk Parameters.
# 

# 1) Debt ceiling.
seth --to-uint256 $(echo "5000000"*10^45 | bc)
export LINE=000000000000000000000d5d238a4abe9806872a4904598d6d88000000000000

# 2) Collateralization ratio 
seth --to-uint256 $(echo "150"*10^25 | bc)
export MAT=000000000000000000000000000000000000000004d8c55aefb8c05b5c000000

# 3) Risk Premium duty
# Total stability fee accumulated for each collateral type inside its rate variable is calculated by adding up DSR base which is equal across all collateral types and the Risk Premium duty which is specific to each one.
seth --to-uint256 1000000000315522921573372069
export DUTY=0000000000000000000000000000000000000000033b2e3ca43176a9d2dfd0a5

# 4) Liquidation penalty.
# A liquidation penalty is imposed on a Vault by increasing it's debt by a percentage before a collateral aucion is kicked off.
seth --to-uint256 $(echo "110"*10^25 | bc)
export CHOP=0000000000000000000000000000000000000000038de60f7c988d0fcc000000

# 5) Maximum size of collateral per auction.
# Vaults with locked collateral amounts greater than liquidation quantity of their collateral type are processed with multiple collateral auctions
seth --to-uint256 $(echo "1000"*10^18 | bc)
export LUMP=00000000000000000000000000000000000000000000003635c9adc5dea00000



# Deploy Spell.
export SPELL=$(seth send --create out/DssAddIlkSpell.bin 'DssAddIlkSpell(bytes32,address,address[8] memory,uint256[5] memory)' $ILK $MCD_PAUSE ["${MCD_VAT#0x}","${MCD_CAT#0x}","${MCD_JUG#0x}","${MCD_SPOT#0x}","${MCD_END#0x}","${JOIN#0x}","${PIP#0x}","${FLIP#0x}"] ["$LINE","$MAT","$DUTY","$CHOP","$LUMP"])

echo SPELL $SPELL


# Slate Spell.
seth send "$MCD_ADM" 'etch(address[] memory)' ["${SPELL#0x}"]


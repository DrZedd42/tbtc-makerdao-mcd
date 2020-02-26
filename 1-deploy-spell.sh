set -ex

# Set accounts.
. account.sh

export ETH_GAS_PRICE=2500000000
export ETH_GAS=6000000

# Setup contract addresses.
# 

# for MAKER_CONTRACT in $(cat deployments/maker_rinkeby.json| jq -r 'keys[]')
# for MAKER_CONTRACT in $(cat deployments/maker_testchain.json | jq -r 'keys[]')
# do
#     ADDRESS=$(cat deployments/maker_testchain.json | jq -r .$MAKER_CONTRACT)
#     export $MAKER_CONTRACT=$ADDRESS
# done

# We load these programatically above.
export MCD_VAT=0x11c8d156e1b5fd883e31e9091874f2af80b02775
export MCD_CAT=0xf2cba62837a52b0c1847f225438c82d050b4ac19
export MCD_JUG=0x0e88266e5d517d6358ad6adabc15475ea2d277d1
export MCD_SPOT=0x2a92ccf051f33912115f86ea0530f4999e3ac1ac
export MCD_PAUSE=0x7adf0ddd0776042b87fa7f504270257c269bf61e
export MCD_PAUSE_PROXY=0xa7653a6f8c956f4bc45d68d55c2f3ce277282a88
export MCD_ADM=0x392e4ff172e6d88c3375de218f6e7e2fa75d3c82
export MCD_END=0xbde07bb0c774f41a59901876454637e3feab8c73
export MCD_JOIN_DAI=0x8c4be23de45f82a4fec7a93f69929bd2a13a4777


# TBTC Token
export TOKEN="0x375AA1c60442A1D0D87D3A8E28bfFcdD82cC7128"


# Set Collateral Type.
# Each ethereum token in Maker Protocol can have multiple collateral types and each one can be initialized with a different set of risk parameters. 
# Affixing an alphabetical letter to the token symbol will help users differentiate these collateral types.
export ILK="$(seth --to-bytes32 "$(seth --from-ascii "TBTC-A")")"


# A set of changes to be made at a time are captured in a Spell smart contract. 
# Once a Spell is deployed, governance can elect its address as an authority which then lets it execute the changes in Maker Protocol. 
# Although it is strictly not required, spells currently are designed to be used once and will lock up after they are executed.


# Deploy price feeds.
export PIP=$(dapp create DSValue)
# Set price to $9000 USD.
seth send $PIP 'poke(bytes32)' $(seth --to-uint256 "$(seth --to-wei 1 ETH)")

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


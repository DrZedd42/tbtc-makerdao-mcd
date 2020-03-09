set -ex

# Set accounts.
. account.sh

# Setup.
# for MAKER_CONTRACT in $(cat deployments/maker_rinkeby.json | jq -r 'keys[]')
for MAKER_CONTRACT in MCD_ADM;
do
    ADDRESS=$(cat deployments/maker_testchain.json | jq -r .$MAKER_CONTRACT)
    export $MAKER_CONTRACT=$ADDRESS
done

export SPELL=$1

seth send "$MCD_ADM" 'vote(address[] memory)' ["${SPELL#0x}"]

# export SLATE=$(seth call "$MCD_ADM" 'etch(address[] memory)' ["${SPELL#0x}"])

# seth send $MCD_ADM 'vote(bytes32)' $SLATE

# Once your spell reveives a majority of votes in Chief.
seth send "$MCD_ADM" 'lift(address)' "$SPELL"

# Schedule the spell for execution.
# The delay is 0s on Ropsten, 300s on mainnet.
sleep 0
seth send "$SPELL" 'schedule()'

# A Governance Delay is imposed on all new executive proposals before they go live.
seth send "$SPELL" 'cast()'

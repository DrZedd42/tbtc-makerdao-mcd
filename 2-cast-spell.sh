set -ex

# Set accounts.
source account.sh

export ETH_GAS=3000000

# Setup.
for MAKER_CONTRACT in $(cat deployments/maker_rinkeby.json| jq -r 'keys[]')
do
    ADDRESS=$(cat deployments/maker_rinkeby.json | jq -r .$MAKER_CONTRACT)
    export $MAKER_CONTRACT=$ADDRESS
done

export SPELL=$1

# Once your spell reveives a majority of votes in Chief.
seth send "$MCD_ADM" 'lift(address)' "${SPELL#0x}"

# Schedule the spell for execution.
# The delay is 0s on Ropsten, 300s on mainnet.
sleep 0
seth send "$SPELL" 'schedule()'

# A Governance Delay is imposed on all new executive proposals before they go live.
seth send "$SPELL" 'cast()'

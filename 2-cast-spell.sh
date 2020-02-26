set -ex

# Set accounts.
source account.sh

export ETH_GAS=3000000

# Setup.
# for MAKER_CONTRACT in $(cat deployments/maker_rinkeby.json | jq -r 'keys[]')
for MAKER_CONTRACT in $(cat deployments/maker_testchain.json | jq -r 'keys[]')
do
    ADDRESS=$(cat deployments/maker_testchain.json | jq -r .$MAKER_CONTRACT)
    export $MAKER_CONTRACT=$ADDRESS
done

export SPELL=$1

# seth send $MCD_ADM 'vote(bytes32)' 0xae8c8faa35d29db5c1c959544e496315548848eb4796524a11202f9c3eed9949

# Once your spell reveives a majority of votes in Chief.
seth send "$MCD_ADM" 'lift(address)' "${SPELL#0x}"

# Schedule the spell for execution.
# The delay is 0s on Ropsten, 300s on mainnet.
sleep 0
seth send "$SPELL" 'schedule()'

# A Governance Delay is imposed on all new executive proposals before they go live.
seth send "$SPELL" 'cast()'

set -ex

# Set accounts.
. account.sh

export ETH_GAS_PRICE=2500000000
export ETH_GAS=6000000



for MAKER_CONTRACT in $(cat deployments/maker_testchain.json | jq -r 'keys[]')
do
    ADDRESS=$(cat deployments/maker_testchain.json | jq -r .$MAKER_CONTRACT)
    export $MAKER_CONTRACT=$ADDRESS
done




# seth call $FAUCET

seth call $MCD_GOV "balanceOf(address)(uint)" $ETH_FROM
seth send $MCD_GOV "approve(address,uint256)(bool)" $MCD_ADM 100000
seth send $MCD_ADM "lock(uint256)" 100000
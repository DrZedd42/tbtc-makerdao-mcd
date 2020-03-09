set -ex

# Set accounts.
. account.sh


for MAKER_CONTRACT in MCD_GOV MCD_ADM;
do
    ADDRESS=$(cat deployments/maker_testchain.json | jq -r .$MAKER_CONTRACT)
    export $MAKER_CONTRACT=$ADDRESS
done


seth call $MCD_GOV "balanceOf(address)(uint)" $ETH_FROM
seth send $MCD_GOV "approve(address,uint256)(bool)" $MCD_ADM 100000000
seth send $MCD_ADM "lock(uint256)" 100000000
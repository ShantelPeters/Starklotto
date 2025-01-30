use starknet::{ContractAddress};
use contracts::DistributPrize::{DistributPrizeDispatcher, IDistributPrizeDispatcherTrait};

use snforge_std::{
    declare, start_cheat_caller_address, stop_cheat_caller_address, ContractClassTrait,
    DeclareResultTrait, spy_events, EventSpyAssertionsTrait, get_class_hash
};

fn __setup__() -> ContractAddress {
    let class_hash = declare("DistributPrize").unwrap().contract_class();

    let mut calldata = array![];

    let (contract_address, _) = class_hash.deploy(@calldata).unwrap();

    contract_address
}

#[test]
fn test_distribute_prize() {
    let contract_address = __setup__();
    let dispatcher = DistributPrizeDispatcher { contract_address };

    dispatcher.total_pool.write!(50);
    let pool_value = dispatcher.total_pool();
    
    assert_eq!(50, pool_value);
}
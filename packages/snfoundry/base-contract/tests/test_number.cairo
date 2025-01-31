use snforge_std::{
    declare, start_cheat_caller_address, stop_cheat_caller_address, ContractClassTrait,
    DeclareResultTrait, spy_events, EventSpyAssertionsTrait, get_class_hash,
};

use starknet::{ContractAddress};

use starklotto::interfaces::INumber::{INumber, INumberDispatcher, INumberDispatcherTrait};
use starklotto::number::Number::{Event, UpdateNumber};
use starklotto::base::errors::Errors::{INVALID_NUMBER};


fn __setup__() -> ContractAddress {
    let class_hash = declare("Number").unwrap().contract_class();

    let mut calldata = array![];

    let (contract_address, _) = class_hash.deploy(@calldata).unwrap();

    contract_address
}

#[test]
fn test_retrieve_value() {
    let contract_address = __setup__();
    let dispatcher = INumberDispatcher { contract_address };

    let value = dispatcher.retrieveValue();
    assert(value == 0, INVALID_NUMBER);
}

#[test]
fn test_store_value() {
    let contract_address = __setup__();
    let dispatcher = INumberDispatcher { contract_address };

    dispatcher.storeValue(32);
    assert(dispatcher.retrieveValue() == 32, INVALID_NUMBER);
}


#[test]
fn test_update_number_event_emission() {
    let contract_address = __setup__();
    let dispatcher = INumberDispatcher { contract_address };
    let mut spy = spy_events();

    dispatcher.storeValue(32);
    assert(dispatcher.retrieveValue() == 32, INVALID_NUMBER);

    // test DonationMade event emission
    let expected_event = Event::UpdateNumber(UpdateNumber { value: 32 });

    spy.assert_emitted(@array![(contract_address, expected_event)]);
}

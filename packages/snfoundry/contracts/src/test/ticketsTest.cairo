use crate::ticket::{
    ITicketContractDispatcher, ITicketContractDispatcherTrait, TicketContract,
    TicketContract::{Event as TicketEvents, TicketPurchase},
};
use core::starknet::{ContractAddress, contract_address_const};
use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address,
    stop_cheat_caller_address, EventSpyAssertionsTrait, spy_events, load,
};

fn deploy_ticket_contract() -> (ITicketContractDispatcher, ContractAddress) {
    let contract = declare("TicketContract").unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@array![]).unwrap();
    let dispatcher = ITicketContractDispatcher { contract_address };
    (dispatcher, contract_address)
}

#[test]
fn test_buy_ticket() {
    let (ticket_contract, ticket_contract_address) = deploy_ticket_contract();
    let buyer: ContractAddress = contract_address_const::<'buyer'>();
    let amount: u32 = 100;

    start_cheat_caller_address(ticket_contract_address, buyer);
    ticket_contract.buy_ticket(amount);

    let mut spy = spy_events();
    let expected_event = TicketEvents::TicketPurchase(TicketPurchase { buyer, amount });
    spy.assert_emitted(@array![(ticket_contract_address, expected_event)]);

    let prize_pool = ticket_contract.get_prize_pool();
    assert_eq!(prize_pool, amount);

    let is_participant = load(ticket_contract_address, selector!("participants"), buyer);
    assert_eq!(is_participant, array![true]);

    stop_cheat_caller_address(ticket_contract_address);
}
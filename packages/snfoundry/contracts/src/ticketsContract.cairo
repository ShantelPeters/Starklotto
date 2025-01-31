#[starknet::interface]
pub trait ITicketContract<TContractState> {
    fn buy_ticket(ref self: TContractState, amount: u32);
    fn get_prize_pool(self: @TContractState) -> u32;
}

#[starknet::contract]
pub mod TicketContract {
    use super::ITicketContract;
    use core::starknet::{ContractAddress, get_caller_address};
    use core::starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    use core::starknet::LegacyMap;

    #[storage]
    pub struct Storage {
        participants: LegacyMap::<ContractAddress, bool>,
        prize_pool: u32,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        TicketPurchase: TicketPurchase,
    }

    #[derive(Drop, starknet::Event)]
    pub struct TicketPurchase {
        pub buyer: ContractAddress,
        pub amount: u32,
    }

    #[abi(embed_v0)]
    impl TicketContractImpl of super::ITicketContract<ContractState> {
        fn buy_ticket(ref self: ContractState, amount: u32) {
            let caller: ContractAddress = get_caller_address();
            if !self.participants.read(caller) {
                self.participants.write(caller, true);
            }
            self.prize_pool.write(self.prize_pool.read() + amount);
            self.emit(TicketPurchase { buyer: caller, amount });
        }

        fn get_prize_pool(self: @ContractState) -> u32 {
            self.prize_pool.read()
        }
    }
}

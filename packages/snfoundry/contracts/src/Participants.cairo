#[starknet::interface]
pub trait IParticipants<TContractState> {
    fn add_participant(ref self: TContractState);
    fn get_participants(self: @TContractState) -> Vec<ContractAddress>;
}

#[starknet::contract]
mod Participants {
    use starknet::storage::Vec;
    use starknet::{ContractAddress, get_caller_address};

    #[storage]
    struct Storage {
        participants: Vec<ContractAddress>,
    }

    #[abi(embed_v0)]
    impl ParticipantsImpl of IParticipants<ContractState> {
        fn add_participant(ref self: ContractState) {
            let caller = get_caller_address();
            if self.participants.iter().any(|addr| *addr == caller) {
                return;
            }
            self.participants.append(caller);
        }

        fn get_participants(self: @ContractState) -> Vec<ContractAddress> {
            self.participants.read()
        }
    }
}

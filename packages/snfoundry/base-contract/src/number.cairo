use starknet::{ContractAddress, contract_address_const};

fn PRAGMA_VRF_ADDRESS() -> ContractAddress {
    contract_address_const::<0x060c69136b39319547a4df303b6b3a26fab8b2d78de90b6bd215ce82e9cb515c>()
}

fn ETH_ADDRESS() -> ContractAddress {
    contract_address_const::<0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7>()
}

#[starknet::contract]
mod Number {
    use starknet::event::EventEmitter;
    use starklotto::interfaces::INumber::{INumber};
    use starklotto::interfaces::IPragmaVRF::{IPragmaVRF};
    use starklotto::base::errors::Errors::{INVALID_NUMBER};
    use pragma_lib::abi::{IRandomnessDispatcher, IRandomnessDispatcherTrait};
    use openzeppelin::token::erc20::{ERC20ABIDispatcher, ERC20ABIDispatcherTrait};
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    use starknet::{ContractAddress, get_caller_address, get_contract_address, get_block_number};
    use super::{PRAGMA_VRF_ADDRESS, ETH_ADDRESS};

    #[storage]
    struct Storage {
        number: u64,
        winner: u64,
        // Randomness Variables
        last_random_number_storage: felt252,
        min_block_number_storage: u64,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        UpdateNumber: UpdateNumber,
        RandomnessRequested: RandomnessRequested,
        RandomnessReceived: RandomnessReceived,
    }

    #[derive(Drop, starknet::Event)]
    pub struct UpdateNumber {
        #[key]
        value: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct RandomnessRequested {
        #[key]
        request_id: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct RandomnessReceived {
        #[key]
        request_id: u64,
        random_word: felt252,
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        self.number.write(0);
    }

    #[abi(embed_v0)]
    impl NumberImpl of INumber<ContractState> {
        fn storeValue(ref self: ContractState, newNumber: u64) -> bool {
            self.number.write(newNumber);
            self.emit(UpdateNumber { value: newNumber });

            true
        }

        fn retrieveValue(self: @ContractState) -> u64 {
            self.number.read()
        }
    }

    #[abi(embed_v0)]
    impl PragmaVRFOracle of IPragmaVRF<ContractState> {
        fn get_last_random_number(self: @ContractState) -> felt252 {
            let last_random = self.last_random_number_storage.read();
            last_random
        }

        fn request_my_randomness(
            ref self: ContractState,
            seed: u64,
            callback_fee_limit: u128,
            publish_delay: u64,
            num_words: u64,
            calldata: Array<felt252>,
        ) {
            let randomness_dispatcher = IRandomnessDispatcher {
                contract_address: PRAGMA_VRF_ADDRESS(),
            };

            // Approve the randomness contract to transfer the callback fee
            // You would need to send some ETH to this contract first to cover the fees
            let eth_dispatcher = ERC20ABIDispatcher {
                contract_address: ETH_ADDRESS() // ETH Contract Address
            };

            eth_dispatcher
                .approve(
                    PRAGMA_VRF_ADDRESS(),
                    (callback_fee_limit + callback_fee_limit / 5).into(),
                );

            // Request the randomness
            let request_id = randomness_dispatcher
                .request_random(
                    seed,
                    get_contract_address(),
                    callback_fee_limit,
                    publish_delay,
                    num_words,
                    calldata,
                );

            let current_block_number = get_block_number();
            self.min_block_number_storage.write(current_block_number + publish_delay);

            self.emit(RandomnessRequested { request_id });
        }

        fn receive_random_words(
            ref self: ContractState,
            requestor_address: ContractAddress,
            request_id: u64,
            random_words: Span<felt252>,
            calldata: Array<felt252>,
        ) {
            let caller_address = get_caller_address();
            assert(caller_address == PRAGMA_VRF_ADDRESS(), 'caller not randomness contract');

            // Make sure that the current block is within publish_delay of the request block
            let current_block_number = get_block_number();
            let min_block_number = self.min_block_number_storage.read();
            assert(min_block_number <= current_block_number, 'block number issue');

            // and that the requestor_address is what we expect it to be (can be self
            // or another contract address), checking for self in this case
            let contract_address = get_contract_address();
            assert(requestor_address == contract_address, 'requestor is not self');

            // Your code using randomness!
            let random_word = *random_words.at(0);
            self.last_random_number_storage.write(random_word);
            self.emit(RandomnessReceived { request_id, random_word });

            // TODO: Update with actual number of participants
            let participants = 10;
            let random_number: u256 = random_word.into();
            let winner = random_number % participants;

            self.winner.write(winner.try_into().unwrap());
        }
    }
}

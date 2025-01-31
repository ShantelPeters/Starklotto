#[starknet::interface]
pub trait INumber<TState> {
    fn storeValue(ref self: TState, newNumber: u64) -> bool;
    fn retrieveValue(self: @TState) -> u64;
}

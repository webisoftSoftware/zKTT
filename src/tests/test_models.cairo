#[cfg(test)]
mod tests {
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use zktt::models::{GameComponent, CardComponent, DeckComponent, DealerComponent,
         HandComponent, MoneyPileComponent, PlayerComponent, EnumGameState, EnumMoveError,
          EnumCardCategory, EnumPlayerState, EnumBlockchainType,
           IBlockchain, IDeck, IDealer, IGameComponent, IPlayer, ICard, IHand, IAsset};
    use zktt::systems::{game::{game, IGameDispatcher, IGameDispatcherTrait}};

    #[test]
    fn test_print() -> () {
        let caller = starknet::contract_address_const::<0x0>();
        let game_system = IGameDispatcher { caller };
        let cards = game_system.create_cards(@caller);

        let mut index = 0;
        loop {
            if index >= cards.len() {
                break ();
            }

            println!("{0}", cards.at(index));
            index += 1;
        };
    }
}
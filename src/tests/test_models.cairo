#[cfg(test)]
mod tests {
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use zktt::models::{ComponentGame, ComponentDeck, ComponentDealer,
         ComponentHand, ComponentMoneyPile, ComponentPlayer, EnumGameState, EnumMoveError,
          EnumCard, EnumPlayerState, EnumBlockchainType,
           IBlockchain, IDeck, IDealer, IGame, IPlayer, IHand, IAsset};
    use zktt::systems::game::table;

    #[test]
    fn test_start() -> () {
        let callers = array![starknet::contract_address_const::<0x0>(),
         starknet::contract_address_const::<0x1>(),
         starknet::contract_address_const::<0x2>()];

        let cards = table::create_cards(callers.at(0));
        //table::distribute_cards()

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
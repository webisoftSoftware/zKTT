#[cfg(test)]
mod tests {
    // import world dispatcher
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
    // import test utils
    use dojo::utils::test::{spawn_test_world, deploy_contract};
    // import test utils
    use zktt::{
        systems::{play::{play, IPlayDispatcher, IPlayDispatcherTrait}},
        models::{CardComponent, PlayerComponent, HandComponent, DealerComponent,
                      DeckComponent, EnumTxError}
    };

    #[test]
    fn test_move() {
        // caller
        let caller = starknet::contract_address_const::<0x0>();

        // models
        let mut models = array![position::TEST_CLASS_HASH, moves::TEST_CLASS_HASH];

        // deploy world with models
        let world = spawn_test_world(["zktt"].span(), models.span());

        // deploy systems contract
        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());

        let connect_system = IConnectDispatcher { contract_address };
        let play_system = IPlayDispatcher { contract_address };
        let disconnect_system = IDisconnectDispatcher { contract_address };

        world.grant_writer(dojo::utils::bytearray_hash(@"zktt"), contract_address);

        // Call connect functions.
        connect_system.join("0x07da79ef7d6");

        // call play functions.
        play_system.distribute_cards();
        play_system.draw();


        let player = PlayerComponent::new("0xffffffffff", "nami2301", 3, 0);
        let card1 = CardComponent::new(player,
            name: "1M".to_string(),
            description: "1 Million Dollars".to_string(),
            card_type: EnumCardCategory::Cash,
            value: 1,
            rank: 0);

        // Check world state
        let hand = get!(world, caller, HandComponent);
        let player = get!(world, caller, Player);

        // Check that we have another card in our hand.
        assert(hand.cards.len() == 6, 'incorrect number of cards after drawing');

        // Check that we have one less move.
        assert(player.moves_remaining == 2, 'incorrect number of moves remaining');

        play_system.play(card1);

        // Check that we have one less move.
        assert(player.moves_remaining == 1, 'incorrect number of moves remaining');

        // Check that we have one less card in our hand.
        assert(hand.cards.len() == 5, 'incorrect number of cards after drawing');
    }
}

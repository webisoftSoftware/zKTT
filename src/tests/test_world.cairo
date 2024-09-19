#[cfg(test)]
mod tests {
    // import world dispatcher
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
    // import test utils
    use dojo::utils::test::{spawn_test_world, deploy_contract};
    // import test utils
    use zktt::{
        systems::{game::{game, IGameDispatcher, IGameDispatcherTrait}},
        models::{CardComponent, PlayerComponent, IPlayer}
    };

    #[test]
    fn test_move() {
        // caller
        let caller = starknet::contract_address_const::<0x0>();

        // models
        let mut models = array![game::TEST_CLASS_HASH];

        // deploy world with models
        let world = spawn_test_world(["zktt"].span(), models.span());

        // deploy systems contract
        let contract_address = world
            .deploy_contract('salt', game::TEST_CLASS_HASH.try_into().unwrap());

        let game_system = IGameDispatcher { contract_address };

        world.grant_writer(dojo::utils::bytearray_hash(@"zktt"), contract_address);

        // Add a new player.
        set!(world, (IPlayer::new('Nami2301', array![], array![], 3, 0)));

        // call play functions.
        let _ = game_system.draw();

        let player = get!(world, caller, (PlayerComponent));

        // Check that we have one less move.
        assert(player.moves_remaining == 2, 'incorrect moves remaining');

        // Check that we have more card in our hand.
        assert(player.ent_hand.len() == 1, 'incorrect number of cards');
    }
}

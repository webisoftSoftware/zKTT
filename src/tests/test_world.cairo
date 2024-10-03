////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
/////////////////////            ____________  /////////////////////////
////////////////////    ___| |/ /_   _|_   _| //////////////////////////
////////////////////   |_  / ' /  | |   | |   //////////////////////////
////////////////////    / /| . \  | |   | |   //////////////////////////
////////////////////   /___|_|\_\ |_|   |_|   //////////////////////////
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////

#[cfg(test)]
mod tests {
    // import world dispatcher
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
    // import test utils
    use dojo::utils::test::{spawn_test_world, deploy_contract};
    // import test utils
    use zktt::{
        systems::{game::{game, IGameDispatcher, IGameDispatcherTrait}},
        models::{PlayerComponent, IPlayer}
    };

    #[test]
    fn test_join() {
        // caller
        let caller = starknet::contract_address_const::<0x0>();

        // Models
        let mut models = array![table::TEST_CLASS_HASH];

        // Deploy world with models
        let world = spawn_test_world(["game"].span(), models.span());

        println!("{0}", table::TEST_CLASS_HASH);

        // Deploy systems contract
        let contract_address = world
            .deploy_contract('salt', game::TEST_CLASS_HASH.try_into().unwrap());

        let game_system = IGameDispatcher { contract_address };

        world.grant_writer(dojo::utils::bytearray_hash(@"zktt-game"), contract_address);

        // Add a new player.
        set!(world, (IPlayer::new(caller, "Nami2301")));

        // call play functions.
        game_system.join("Nami2301");
        game_system.join("Nami23012");

        let player = get!(world, caller, (PlayerComponent));

        // Check that we have one less move.
        assert(player.moves_remaining == 2, 'incorrect moves remaining');
    }
}

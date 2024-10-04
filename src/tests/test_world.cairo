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
    use starknet::ContractAddress;
    // import world dispatcher
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
    // import test utils
    use dojo::utils::test::{spawn_test_world, deploy_contract};
    use dojo::model::Model;
    // import test utils
    use zktt::{
        systems::{game::{table, ITableDispatcher, ITableDispatcherTrait}},
        models::components::{ComponentGame, ComponentPlayer, ComponentDealer, ComponentHand,
         ComponentDeck, component_game, component_player, component_dealer, component_deck,
         component_hand, EnumPlayerState, EnumGameState, IPlayer}
    };

    // Deploy world with supplied components registered.
    fn deploy_world() -> (ITableDispatcher, IWorldDispatcher) {

         // Deploy a world with pre-registered models.
         // Arg 1: Namespace of the world
         // Arg 2: A span list of all the models' class hashes to register.
         let models: Array<felt252> = array![component_game::TEST_CLASS_HASH,
                          component_player::TEST_CLASS_HASH, component_dealer::TEST_CLASS_HASH,
                          component_hand::TEST_CLASS_HASH, component_deck::TEST_CLASS_HASH];

         // NOTE: All model names somehow get converted to snake case, but you have to import the
         // snake case versions from the same path where the components are from.
        let world: IWorldDispatcher = spawn_test_world(["zktt"].span(), models.span());

        // Deploys a contract with systems.
        // Arg 2: Calldata for constructor.
        let contract_address: ContractAddress =
            world.deploy_contract('salt', table::TEST_CLASS_HASH.try_into().unwrap());

        // Grant writing to components.
        // Arg 1: Component selector hash.
        world.grant_writer(Model::<ComponentGame>::selector(), contract_address);
        world.grant_writer(Model::<ComponentPlayer>::selector(), contract_address);
        world.grant_writer(Model::<ComponentHand>::selector(), contract_address);
        world.grant_writer(Model::<ComponentDeck>::selector(), contract_address);
        world.grant_writer(Model::<ComponentDealer>::selector(), contract_address);

        // Setup contract object.
        let table: ITableDispatcher = ITableDispatcher { contract_address };

        return (table, world);
    }

    #[test]
    fn test_join() {
        let second_caller = starknet::contract_address_const::<0x0b>();
        let (mut table, world) = deploy_world();

        // Join player one.
        table.join("Player 1");

        // Set player two as the next caller.
        starknet::testing::set_account_contract_address(second_caller);
        starknet::testing::set_contract_address(second_caller);

        // Join player two.
        table.join("Player 2");

        let player_two = get!(world, (second_caller), (ComponentPlayer));
        assert!(player_two.m_state == EnumPlayerState::Joined, "Player 2 should have joined!");
    }
    
    #[test]
     fn test_start() {
        let first_caller = starknet::contract_address_const::<0x0a>();
        let second_caller = starknet::contract_address_const::<0x0b>();
        let (mut table, world) = deploy_world();

        // Set player one as the next caller.
        starknet::testing::set_account_contract_address(first_caller);
        starknet::testing::set_contract_address(first_caller);

        // Make two players join.
        // Join player one.
        table.join("Player 1");

        // Set player two as the next caller.
        starknet::testing::set_account_contract_address(second_caller);
        starknet::testing::set_contract_address(second_caller);

        // Join player two.
        table.join("Player 2");

        // Start the game.
        table.start();

        let game = get!(world, (world.contract_address), (ComponentGame));
        assert!(game.m_state == EnumGameState::Started, "Game should have started!");

        // Check players' hands.
        let player1_hand = get!(world, (first_caller), (ComponentHand));
        println!("Player 1's hand: {0}", player1_hand);
        assert!(player1_hand.m_cards.len() == 5, "Player 1 should have received 5 cards!");
        let player2_hand = get!(world, (first_caller), (ComponentHand));
        println!("Player 2's hand: {0}", player2_hand);
        assert!(player2_hand.m_cards.len() == 5, "Player 1 should have received 5 cards!");
     }
}

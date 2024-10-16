// Copyright (c) 2024 zkTT
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the Software
// is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
// THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.
////////////////////////////////////////////////////////////////////////////////////////////////////


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
         component_hand, EnumGameState, IDealer, IPlayer}
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

    fn set_up_cards(ref world: IWorldDispatcher) {
        let unique_cards_in_order = table::_create_cards(ref world);
        let all_cards_in_order = table::_flatten(unique_cards_in_order);

        let dealer: ComponentDealer = IDealer::new(world.contract_address, all_cards_in_order);
        set!(world, (dealer));
    }

    #[test]
    fn test_dummy_player() {
        let (mut table, world) = deploy_world();
        // Join player one.
        table.join("Player 1");

        let second_caller = starknet::contract_address_const::<0x0b>();
        // Set unknown player as the next caller.
        starknet::testing::set_contract_address(second_caller);

        let unknown_player = get!(world, (second_caller), (ComponentPlayer));
        println!("{0}", unknown_player);
        assert!(unknown_player.m_ent_owner == second_caller, "Dummy player created...!");
    }

    #[test]
    fn test_join() {
        let second_caller = starknet::contract_address_const::<0x0b>();
        let (mut table, world) = deploy_world();

        // Join player one.
        table.join("Player 1");

        // Set player two as the next caller.
        starknet::testing::set_contract_address(second_caller);

        // Join player two.
        table.join("Player 2");

        let game = get!(world, (world.contract_address), (ComponentGame));
        assert!(game.m_players.len() == 2, "Players should have joined!");
    }

    #[test]
    #[should_panic(expected: ("Dealer should have 95 cards after distributing to 2 players!",))]
    fn test_start() {
       let first_caller = starknet::contract_address_const::<0x0a>();
       let second_caller = starknet::contract_address_const::<0x0b>();
       let (mut table, mut world) = deploy_world();

       set_up_cards(ref world);

       let mut dealer = get!(world, (world.contract_address), (ComponentDealer));
       assert!(!dealer.m_cards.is_empty(), "Dealer should have cards!");

       // Set player one as the next caller.
       starknet::testing::set_contract_address(first_caller);

       // Make two players join.
       // Join player one.
       table.join("Player 1");

       // Set player two as the next caller.
       starknet::testing::set_contract_address(second_caller);

       // Join player two.
       table.join("Player 2");

       // Provide a deterministic seed.
       starknet::testing::set_block_timestamp(240);
       starknet::testing::set_nonce(0x111);


       // Start the game.
       table.start();

       // Check players' hands.
       let player1_hand = get!(world, (first_caller), (ComponentHand));
       println!("Caller {0}", player1_hand);
       assert!(player1_hand.m_cards.len() == 5, "Player 1 should have received 5 cards!");
       let player2_hand = get!(world, (second_caller), (ComponentHand));
       println!("Caller {0}", player2_hand);
       assert!(player2_hand.m_cards.len() == 5, "Player 1 should have received 5 cards!");

       let game = get!(world, (world.contract_address), (ComponentGame));
       assert!(game.m_state == EnumGameState::Started, "Game should have started!");

       println!("{0}", dealer.m_cards.len());
       assert!(dealer.m_cards.len() == 95, "Dealer should have 95 cards after distributing to 2 players!");
    }

    #[test]
    fn test_new_turn() {
       let first_caller = starknet::contract_address_const::<0x0a>();
       let second_caller = starknet::contract_address_const::<0x0b>();
       let (mut table, mut world) = deploy_world();

       // Set player one as the next caller.
       starknet::testing::set_contract_address(first_caller);

       // Make two players join.
       // Join player one.
       table.join("Player 1");

       // Set player two as the next caller.
       starknet::testing::set_contract_address(second_caller);

       // Join player two.
       table.join("Player 2");

       table.start();

       let game = get!(world, (world.contract_address), (ComponentGame));
       assert!(game.m_player_in_turn == first_caller, "Player 1 should have started their turn!");
    }

    #[test]
    #[should_panic(expected: ("Cannot draw mid-turn", 'ENTRYPOINT_FAILED'))]
    fn test_draw() {
       let first_caller = starknet::contract_address_const::<0x0a>();
       let second_caller = starknet::contract_address_const::<0x0b>();
       let (mut table, mut world) = deploy_world();

       set_up_cards(ref world);

       // Set player one as the next caller.
       starknet::testing::set_contract_address(first_caller);

       // Make two players join.
       // Join player one.
       table.join("Player 1");

       // Set player two as the next caller.
       starknet::testing::set_contract_address(second_caller);

       // Join player two.
       table.join("Player 2");

       table.start();

       let mut dealer = get!(world, (world.contract_address), (ComponentDealer));
       assert!(!dealer.m_cards.is_empty(), "Dealer should have cards!");

       // Set player one as the next caller.
       starknet::testing::set_contract_address(first_caller);

       table.draw(false);

       let hand = get!(world, (first_caller), (ComponentHand));
       assert!(hand.m_cards.len() == 7, "Player 1 should have two more cards at this point!");

       // Should panic.
       table.draw(false);
    }
}

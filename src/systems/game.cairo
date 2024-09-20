use zktt::models::{CardComponent, PlayerComponent, EnumCardCategory, EnumGameState, EnumMoveError};
use starknet::ContractAddress;

#[dojo::interface]
trait IGame {
    fn join(ref world: IWorldDispatcher, username: ByteArray) -> ();
    fn start(ref world: IWorldDispatcher) -> ();
    fn draw(ref world: IWorldDispatcher) -> ();
    fn play(ref world: IWorldDispatcher, card: CardComponent) -> ();
    fn end_turn(ref world: IWorldDispatcher) -> ();
    fn leave(ref world: IWorldDispatcher) -> ();
    fn end(ref world: IWorldDispatcher) -> ();
}

#[dojo::contract]
mod game {
    use super::{IGame};
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use zktt::models::{GameComponent, CardComponent, DeckComponent, DealerComponent,
     HandComponent, PlayerComponent, EnumGameState, EnumMoveError, EnumCardCategory, IGameComponent,
      IPlayer, ICard, IHand, IAsset};

    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    /////////////////////////////// PUBLIC /////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    #[abi(embed_v0)]
    impl IGameImpl of IGame<ContractState> {
        fn join(ref world: IWorldDispatcher, username: ByteArray) -> () {
            let mut game_component = get!(world, (world.contract_address), (GameComponent));
            assert!(game_component.state == EnumGameState::WaitingForPlayers, "Game has already started");
            assert!(game_component.players.len() < 5, "Lobby already full");

            game_component.players.append(get_caller_address());
            set!(world, (game_component));

            let new_player: PlayerComponent = IPlayer::new(get_caller_address(), username);
            set!(world, (new_player));

            return ();
        }

        fn start(ref world: IWorldDispatcher) -> () {
            let seed = world.contract_address;
            let game_lobby = get!(world, (seed), (GameComponent));

            assert!(game_lobby.state == EnumGameState::WaitingForPlayers, "Game has already started");
            assert!(game_lobby.players.len() >= 2, "Missing at least a player before starting");

            let mut game_component = get!(world, (seed), (GameComponent));
            game_component.state = EnumGameState::Started;

            let mut dealer_component = get!(world, (seed), (DealerComponent));
            let mut cards = create_cards(generate_seed(@seed, @game_component.players));
            set!(world, (game_component));

            let mut game_component = get!(world, (seed), (GameComponent));
            let mut world_ref = world;
            distribute_cards(ref world_ref, game_component.players, ref cards);
            dealer_component.cards = cards;
            set!(world, (dealer_component));
            return ();
        }

        fn draw(ref world: IWorldDispatcher) -> () {
            let seed = world.contract_address;
            assert!(get!(world, (seed), (GameComponent)).state == EnumGameState::Started,
                         "Game has not started yet");

            let (mut hand, player) = get!(world, (get_caller_address()), (HandComponent, PlayerComponent));
            let mut pile = get!(world, (seed), DealerComponent);
            let card_opt = draw_card_from_pile(ref pile);

            if card_opt.is_none() {
                panic!("Deck does not have any more cards!");
            }

            return match hand.add(card_opt.unwrap()) {
                Result::Ok(()) => {
                    set!(world, (hand));
                    return ();
                },
                Result::Err(_) => panic!("Error adding card to hand of {0}", player.username)
            };
        }

        fn play(ref world: IWorldDispatcher, card: CardComponent) -> () {
            assert!(get!(world, (world.contract_address), (GameComponent)).state == EnumGameState::Started,
                         "Game has not started yet");

            let player_component = get!(world, get_caller_address(), (PlayerComponent));
            set!(world, (player_component));
            return ();
        }

        fn end_turn(ref world: IWorldDispatcher) -> () {
            assert!(get!(world, (world.contract_address), (GameComponent)).state == EnumGameState::Started,
                         "Game has not started yet");

            let player_component = get!(world, get_caller_address(), (PlayerComponent));
            set!(world, (player_component));
            return ();
        }

        fn leave(ref world: IWorldDispatcher) -> () {
            let player_component = get!(world, (get_caller_address()), (PlayerComponent));
            let mut game_component = get!(world, (world.contract_address), (GameComponent));

            if let Option::Some(_) = game_component.contains_player(@player_component.ent_owner) {
                delete!(world, (player_component));
                set!(world, (game_component));
                return ();
            }

            panic!("Player not Found!");
        }

        fn end(ref world: IWorldDispatcher) -> () {
            assert!(get!(world, (world.contract_address), (GameComponent)).state == EnumGameState::Started,
                         "Game has not started yet");

            let mut game_component = get!(world, (world.contract_address), (GameComponent));
            game_component.state = EnumGameState::Ended;

            set!(world, (game_component));
            return ();
        }
    }

    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    /////////////////////////////// INTERNAL ///////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    fn generate_seed(world_address: @ContractAddress, players: @Array<ContractAddress>) -> felt252 {
        // TODO: Generate random ordered card components for the beginning of the game.
        return (get_block_timestamp() * players.len().into() * 31).into();
    }

    fn create_cards(seed: felt252) -> Array<CardComponent> {
        let asset = IAsset::new(get_caller_address(), "ETH [2]", 2, 5);
        let ton = ICard::new(get_caller_address(), EnumCardCategory::Asset(asset));
        return array![ton];
    }

    fn distribute_cards(ref world: IWorldDispatcher, mut players: Array<ContractAddress>,
            ref cards: Array<CardComponent>) -> () {
        if players.is_empty() {
            panic!("There are no players to distribute cards to!");
        }

        let mut index = 0;
        let mut current_player = players.pop_front().unwrap();
        return loop {
            if index >= players.len() {
                break ();
            }

            // Cycle through players every 5 cards given.
            if index != 0 && index % 5 == 0 {
                if let Option::Some(next_player) = players.pop_front() {
                    current_player = next_player;
                }
            }

            if let Option::Some(card) = cards.pop_front() {
                let mut player_hand = get!(world, (current_player), (HandComponent));
                match player_hand.add(card) {
                    Result::Ok(()) => {
                        set!(world, (player_hand));
                    },
                    Result::Err(err) => {
                        // Maybe send an event.
                        panic!("Error happened when adding card Error => {0}", err);
                    }
                };
            }
            index -= 1;
        };
    }

    fn draw_card_from_pile(ref card_pile: DealerComponent) -> Option<CardComponent> {
        if card_pile.cards.is_empty() {
            return Option::None;
        }
        let asset = IAsset::new(get_caller_address(), "ETH [1]", 1, 6);

        return Option::Some(ICard::new(get_caller_address(), EnumCardCategory::Asset(asset)));
    }
}

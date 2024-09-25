use zktt::models::{ActionComponent, PlayerComponent, EnumCardCategory, EnumGameState, EnumMoveError};
use starknet::ContractAddress;

#[dojo::interface]
trait IGame {
    fn join(ref world: IWorldDispatcher, username: ByteArray) -> ();
    fn start(ref world: IWorldDispatcher) -> ();
    fn new_turn(ref world: IWorldDispatcher) -> ();
    fn draw(ref world: IWorldDispatcher) -> ();
    fn play(ref world: IWorldDispatcher, action: ActionComponent) -> ();
    fn end_turn(ref world: IWorldDispatcher) -> ();
    fn leave(ref world: IWorldDispatcher) -> ();
    fn end(ref world: IWorldDispatcher) -> ();
}

#[dojo::contract]
mod game {
    use super::{IGame};
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use zktt::models::{GameComponent, ActionComponent, CardComponent, DeckComponent, DealerComponent,
     HandComponent, MoneyPileComponent, PlayerComponent, EnumActionType, EnumGameState, EnumMoveError,
      EnumCardCategory, EnumPlayerState, EnumBlockchainType,
       IBlockchain, IDealer, IGameComponent, IAction, IPlayer, ICard, IHand, IAsset};

    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    /////////////////////////////// PUBLIC /////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    #[abi(embed_v0)]
    impl IGameImpl of IGame<ContractState> {
        fn join(ref world: IWorldDispatcher, username: ByteArray) -> () {
            let mut game = get!(world, (world.contract_address), (GameComponent));
            assert!(game.state == EnumGameState::WaitingForPlayers, "Game has already started");
            assert!(game.players.len() < 5, "Lobby already full");

            game.add_player(get_caller_address());
            set!(world, (game));

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
            let mut card_container = array![];
            create_assets(@world.contract_address, ref card_container);
            set!(world, (game_component));

            let mut game_component = get!(world, (seed), (GameComponent));
            let mut world_ref = world;
            distribute_cards(ref world_ref, game_component.players, ref card_container);
            dealer_component.cards = card_container;
            set!(world, (dealer_component));
            return ();
        }

        fn new_turn(ref world: IWorldDispatcher) -> () {
            let game = get!(world, (world.contract_address), (GameComponent));
            assert!(game.state == EnumGameState::Started, "Game has not started yet");

            let mut player = get!(world, get_caller_address(), (PlayerComponent));
            assert!(player.state == EnumPlayerState::TurnEnded, "Not a valid turn");
            player.state = EnumPlayerState::TurnStarted;
            set!(world, (player));
        }

        fn draw(ref world: IWorldDispatcher) -> () {
            let seed = world.contract_address;
            let (mut hand, mut player) = get!(world, (get_caller_address()), (HandComponent, PlayerComponent));
            assert!(player.state == EnumPlayerState::TurnStarted, "Not a valid turn");

            let mut dealer = get!(world, (seed), DealerComponent);
            let card_opt = dealer.pop_card();

            if card_opt.is_none() {
                panic!("Deck does not have any more cards!");
            }

            return match hand.add(card_opt.unwrap()) {
                Result::Ok(()) => {
                    player.moves_remaining -= 1;
                    set!(world, (hand, player));
                    return ();
                },
                Result::Err(_) => panic!("Error adding card to hand of {0}", player.username)
            };
        }

        fn play(ref world: IWorldDispatcher, action: ActionComponent) -> () {
            assert!(get!(world, (world.contract_address), (GameComponent)).state == EnumGameState::Started,
                         "Game has not started yet");

            let caller = get_caller_address();
            let mut player = get!(world, get_caller_address(), (PlayerComponent));
            let mut world_cpy = world;
            apply_action(ref world_cpy, @caller, action);

            player.moves_remaining -= 1;
            set!(world, (player));
            return ();
        }

        fn end_turn(ref world: IWorldDispatcher) -> () {
            assert!(get!(world, (world.contract_address), (GameComponent)).state == EnumGameState::Started,
                         "Game has not started yet");

            let mut player = get!(world, get_caller_address(), (PlayerComponent));
            assert!(player.state == EnumPlayerState::TurnStarted, "Not a valid turn");

            player.state = EnumPlayerState::TurnEnded;
            set!(world, (player));
            return ();
        }

        fn leave(ref world: IWorldDispatcher) -> () {
            let player = get!(world, (get_caller_address()), (PlayerComponent));
            let mut game = get!(world, (world.contract_address), (GameComponent));

            if let Option::Some(_) = game.contains_player(@player.ent_owner) {
                game.remove_player(@get_caller_address());
                delete!(world, (player));
                set!(world, (game));
                return ();
            }

            panic!("Player not Found!");
        }

        fn end(ref world: IWorldDispatcher) -> () {
            assert!(get!(world, (world.contract_address), (GameComponent)).state == EnumGameState::Started,
                         "Game has not started yet");

            let mut game = get!(world, (world.contract_address), (GameComponent));
            game.state = EnumGameState::Ended;

            set!(world, (game));
            return ();
        }
    }

    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    /////////////////////////////// INTERNAL ///////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    fn apply_action(ref world: IWorldDispatcher, caller: @ContractAddress, action: ActionComponent) -> () {
        let (mut _hand, mut _deck, mut _money) = get!(world, (*caller), (HandComponent, DeckComponent, MoneyPileComponent));
        match action.get_type() {
             EnumActionType::DrawTwo((_card1, _card2)) => {},
             EnumActionType::Exchange((_card1, _card2)) => {},
             EnumActionType::GetFees(_gas_fee_component) => {},
             EnumActionType::MajorityAttack(_majority_component) => {},
             EnumActionType::StealBlockchain(_blockchain_component) => {},
             EnumActionType::StealAssetGroup(_asset_group_component) => {},
            _ => { panic!("Invalid or illegal move!"); }
        };
        set!(world, (action));
        return ();
    }

    fn generate_seed(world_address: @ContractAddress, players: @Array<ContractAddress>) -> felt252 {
        // TODO: Generate random ordered card components for the beginning of the game.
        return (get_block_timestamp() * players.len().into() * 31).into();
    }

    fn create_assets(world_address: @ContractAddress, ref container: Array<CardComponent>) -> () {
        let asset = IAsset::new(*world_address, "ETH [2]", 2, 5);
        let ton = ICard::new(*world_address, EnumCardCategory::Asset(asset));
        container.append(ton);
        return ();
    }

    fn create_blockchains(world_address: @ContractAddress, ref container: Array<CardComponent>) -> () {
        let blockchain = IBlockchain::new(*world_address, "Bitcoin", EnumBlockchainType::Green, 2, 2, 5);
        let bc = ICard::new(*world_address, EnumCardCategory::Blockchain(blockchain));
        container.append(bc);
        return ();
    }

    fn create_action_cards(world_address: @ContractAddress, ref container: Array<CardComponent>) -> () {
    }

    fn shuffle(ref world: IWorldDispatcher) -> () {

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
}

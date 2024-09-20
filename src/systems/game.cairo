use zktt::models::{CardComponent, PlayerComponent, EnumCardCategory, EnumGameState, EnumMoveError};
use starknet::ContractAddress;


#[derive(Copy, Drop, Serde, PartialEq, Introspect)]
enum EnumTxError {
    InvalidMove: EnumMoveError,
    GameAlreadyStarted: (),
    GameNotStarted: (),
    NoPlayersToDistribute: (),
    InvalidPlayer: ()
}

impl EnumMoveErrorIntoEnumTxError of Into<EnumMoveError, EnumTxError> {
    fn into(self: EnumMoveError) -> EnumTxError {
        return EnumTxError::InvalidMove(self);
    }
}

#[dojo::interface]
trait IGame {
    fn start(ref world: IWorldDispatcher, lobby: felt252) -> Result<(), EnumTxError>;
    fn join(ref world: IWorldDispatcher, lobby: felt252, username: ByteArray) -> Result<(), EnumTxError>;
    fn draw(ref world: IWorldDispatcher, lobby: felt252) -> Result<(), EnumTxError>;
    fn play(ref world: IWorldDispatcher, lobby: felt252, card: CardComponent) -> Result<(), EnumTxError>;
    fn end_turn(ref world: IWorldDispatcher, lobby: felt252) -> Result<(), EnumTxError>;
    fn leave(ref world: IWorldDispatcher, lobby: felt252) -> Result<(), EnumTxError>;
    fn end(ref world: IWorldDispatcher, lobby: felt252) -> Result<(), EnumTxError>;
}

#[dojo::contract]
mod game {
    use super::{IGame, EnumTxError};
    use starknet::{ContractAddress, get_caller_address};
    use zktt::models::{GameComponent, CardComponent, CardPileComponent, PlayerComponent,
     EnumGameState, EnumMoveError, EnumCardCategory, IGameComponent, IPlayer, ICard};

    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    /////////////////////////////// PUBLIC /////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    #[abi(embed_v0)]
    impl IGameImpl of IGame<ContractState> {
        fn start(ref world: IWorldDispatcher, lobby: felt252) -> Result<(), EnumTxError> {
            let game_lobby = get!(world, (0), (GameComponent));
            // Check if game has not started.
            assert!(game_lobby.state == EnumGameState::WaitingForPlayers, "Game has already started");
            // Check if we have enough players to start a new game.
            assert!(game_lobby.players.len() >= 2, "Missing at least a player before starting");

            let mut game_component = get!(world, (lobby), (GameComponent));
            game_component.state = EnumGameState::Started;
            set!(world, (game_component));

            let mut new_player: PlayerComponent = IPlayer::new(get_caller_address(), "Nami",
             array![], array![], array![]);
            let mut players = array![new_player];

            return match distribute_cards(players) {
                Result::Ok(mut updated_players) => {
                    // Update players in world.
                    while !updated_players.is_empty() {
                        if let Option::Some(player) = updated_players.pop_front() {
                            set!(world, (player));
                        }
                    };
                    return Result::Ok(());
                },
                Result::Err(err) => {
                    return Result::Err(err);
                }
            };
        }

        fn join(ref world: IWorldDispatcher, lobby: felt252, username: ByteArray) -> Result<(), EnumTxError> {
            let mut game_lobby = get!(world, (lobby), (GameComponent));
            assert!(game_lobby.state == EnumGameState::WaitingForPlayers, "Game has already started");
            assert!(game_lobby.players.len() < 5, "Lobby already full");

            let mut new_player: PlayerComponent = IPlayer::new(get_caller_address(), username,
                         array![], array![], array![]);

            game_lobby.players.append(new_player);
            set!(world, (game_lobby));
            return Result::Ok(());
        }

        fn draw(ref world: IWorldDispatcher, lobby: felt252) -> Result<(), EnumTxError> {
            assert!(get!(world, (lobby), (GameComponent)).state == EnumGameState::Started,
                         "Game has not started yet");

            let mut player_component = get!(world, (get_caller_address()), (PlayerComponent));
            let card = draw_card_from_pile();
            return match player_component.add_to_hand(card) {
                Result::Ok(()) => {
                    set!(world, (player_component));
                    return Result::Ok(());
                },
                Result::Err(err) => {
                    return Result::Err(err.into());
                }
            };
        }

        fn play(ref world: IWorldDispatcher, lobby: felt252, card: CardComponent) -> Result<(), EnumTxError> {
            assert!(get!(world, (lobby), (GameComponent)).state == EnumGameState::Started,
                         "Game has not started yet");

            let player_component = get!(world, get_caller_address(), (PlayerComponent));
            set!(world, (player_component));
            return Result::Ok(());
        }

        fn end_turn(ref world: IWorldDispatcher, lobby: felt252) -> Result<(), EnumTxError> {
            assert!(get!(world, (lobby), (GameComponent)).state == EnumGameState::Started,
                         "Game has not started yet");

            let player_component = get!(world, get_caller_address(), (PlayerComponent));
            set!(world, (player_component));
            return Result::Ok(());
        }

        fn leave(ref world: IWorldDispatcher, lobby: felt252) -> Result<(), EnumTxError> {
            assert!(get!(world, (lobby), (GameComponent)).state == EnumGameState::Started,
                         "Game has not started yet");

            let player_component = get!(world, (get_caller_address()), (PlayerComponent));
            let mut game_component = get!(world, (lobby), (GameComponent));

            if let Option::Some(_) = game_component.remove_player(@player_component.username) {
                delete!(world, (player_component));
                set!(world, (game_component));
                return Result::Ok(());
            }

            return Result::Err(EnumTxError::InvalidPlayer);
        }

        fn end(ref world: IWorldDispatcher, lobby: felt252) -> Result<(), EnumTxError> {
            assert!(get!(world, (lobby), (GameComponent)).state == EnumGameState::Started,
                         "Game has not started yet");

            let mut game_component = get!(world, (lobby), (GameComponent));
            game_component.state = EnumGameState::Ended;

            set!(world, (game_component));
            return Result::Ok(());
        }
    }

    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    /////////////////////////////// INTERNAL ///////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    fn distribute_cards(mut players: Array<PlayerComponent>) -> Result<Array<PlayerComponent>, EnumTxError> {
        let mut index = players.len();
        let mut new_array = ArrayTrait::<PlayerComponent>::new();

        if index == 0 {
            return Result::Err(EnumTxError::NoPlayersToDistribute);
        }

        // TODO: Generate random ordered card components for the beginning of the game.
        let mut cards = array![];

        let mut current_player = players.pop_front().unwrap();
        while index != 0 {

            // Cycle through players every 5 cards given.
            if index != cards.len() && index % 5 == 0 {
                if let Option::Some(next_player) = players.pop_front() {
                    new_array.append(current_player);
                    current_player = next_player;
                }
            }

            if let Option::Some(card) = cards.pop_front() {
                match current_player.add_to_hand(card) {
                    Result::Err(_err) => {
                        // Maybe send an event.
                        break;
                    },
                    _ => {}
                };
            }
            index -= 1;
        };
        return Result::Ok(new_array);
    }

    fn draw_card_from_pile() -> CardComponent {
        // TODO
        return ICard::new(EnumCardCategory::Eth(1), 6);
    }
}

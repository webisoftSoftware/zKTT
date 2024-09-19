use zktt::models::{CardComponent, PlayerComponent, EnumCardCategory, EnumMoveError};
use starknet::ContractAddress;


#[derive(Copy, Drop, Serde, PartialEq, Introspect)]
enum EnumTxError {
    GameAlreadyStarted: (),
    GameNotStarted: (),
    NoPlayersToDistribute: ()
}

#[dojo::interface]
trait IGame {
    fn new_game(ref world: IWorldDispatcher) -> Result<(), EnumTxError>;
    fn draw(ref world: IWorldDispatcher) -> Result<(), EnumMoveError>;
    fn play(ref world: IWorldDispatcher, card: CardComponent) -> Result<(), EnumMoveError>;
    fn end_turn(ref world: IWorldDispatcher) -> Result<(), EnumMoveError>;
    fn end_game(ref world: IWorldDispatcher) -> Result<(), EnumTxError>;
}

#[dojo::contract]
mod game {
    use super::{IGame, EnumTxError};
    use starknet::{ContractAddress, get_caller_address};
    use zktt::models::{CardComponent, PlayerComponent, EnumMoveError, IPlayer, ICard, EnumCardCategory};

    #[derive(Drop, Serde)]
    #[dojo::model]
    #[dojo::event]
    struct HasWon {
        #[key]
        winner: PlayerComponent,
        score: u32
    }

    #[abi(embed_v0)]
    impl IGameImpl of IGame<ContractState> {
        fn new_game(ref world: IWorldDispatcher) -> Result<(), EnumTxError> {
            let mut new_player = IPlayer::new('nami2301', array![], array![], 3, 0);
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

        fn draw(ref world: IWorldDispatcher) -> Result<(), EnumMoveError> {
            let mut player_component = get!(world, get_caller_address(), (PlayerComponent));
            let card = draw_random_card();
            match player_component.add_to_hand(card) {
                Result::Err(err) => {
                    return Result::Err(err);
                },
                _ => {}
            }
            set!(world, (player_component));
            return Result::Ok(());
        }

        fn play(ref world: IWorldDispatcher, card: CardComponent) -> Result<(), EnumMoveError> {
            let player_component = get!(world, get_caller_address(), (PlayerComponent));
            set!(world, (player_component));
            return Result::Ok(());
        }

        fn end_turn(ref world: IWorldDispatcher) -> Result<(), EnumMoveError> {
            let player_component = get!(world, get_caller_address(), (PlayerComponent));
            set!(world, (player_component));
            return Result::Ok(());
        }

        fn end_game(ref world: IWorldDispatcher) -> Result<(), EnumTxError> {
            let player_component = get!(world, get_caller_address(), (PlayerComponent));
            set!(world, (player_component));
            return Result::Ok(());
        }
    }

    // Internal Functions.
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
                index -= 1;
            }
        };
        return Result::Ok(new_array);
    }

    fn draw_random_card() -> CardComponent {
        // TODO
        return ICard::new(EnumCardCategory::Eth(1), 6);
    }
}

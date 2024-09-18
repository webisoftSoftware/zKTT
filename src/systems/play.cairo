use zktt::models::{CardComponent, EnumMoveError};
use starknet::ContractAddress;


#[derive(Copy, Drop, Serde, PartialEq, Introspect)]
enum EnumTxError {
    GameAlreadyStarted: (),
    GameNotStarted: ()
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
    use zktt::models::{CardComponent, PlayerComponent, EnumMoveError};

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
            return Result::Ok(());
        }

        fn draw(ref world: IWorldDispatcher) -> Result<(), EnumMoveError> {
            return Result::Ok(());
        }

        fn play(ref world: IWorldDispatcher, card: CardComponent) -> Result<(), EnumMoveError> {
            return Result::Ok(());
        }

        fn end_turn(ref world: IWorldDispatcher) -> Result<(), EnumMoveError> {
            return Result::Ok(());
        }

        fn end_game(ref world: IWorldDispatcher) -> Result<(), EnumTxError> {
            return Result::Ok(());
        }
    }
}

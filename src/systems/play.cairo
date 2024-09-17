use zktt::models::{CardComponent, PlayerComponent, EnumTxError};
use starknet::ContractAddress;

#[dojo::interface]
trait IPlay {
    fn distribute_cards(ref world: IWorldDispatcher, dealer_address: ContractAddress) -> Result<(), EnumTxError>;
    fn draw(ref world: IWorldDispatcher, dealer_address: ContractAddress) -> Result<(), EnumTxError>;
    fn play(ref world: IWorldDispatcher, card: CardComponent) -> Result<(), EnumTxError>;
    fn take_from(ref world: IWorldDispatcher, card: CardComponent, recipient: ContractAddress) -> Result<(), EnumTxError>;
    fn give_to(ref world: IWorldDispatcher, card: CardComponent, recipient: ContractAddress) -> Result<(), EnumTxError>;
    fn swap_with(ref world: IWorldDispatcher, card_given: CardComponent,
        recipient: ContractAddress, card_taken: CardComponent) -> Result<(), EnumTxError>;
    fn assign_winner(ref world: IWorldDispatcher, player: PlayerComponent) -> Result<(), EnumTxError>;
}

#[dojo::contract]
mod play {
    use super::IPlay;
    use starknet::{ContractAddress, get_caller_address};
    use zktt::models::{CardComponent, PlayerComponent, HandComponent, DeckComponent, EnumTxError,
     IPlayerComponent, ICardComponent, IHandComponent, IDeckComponent, DealerComponent};

    #[derive(Drop, Serde, Introspect)]
    #[dojo::model]
    #[dojo::event]
    struct CardDrew {
        #[key]
        from: PlayerComponent,
        card: CardComponent
    }

    #[derive(Drop, Serde, Introspect)]
    #[dojo::model]
    #[dojo::event]
    struct CardPlayed {
        #[key]
        from: PlayerComponent,
        card: CardComponent
    }

    #[derive(Drop, Serde, Introspect)]
    #[dojo::model]
    #[dojo::event]
    struct CardMoved {
        #[key]
        from: PlayerComponent,
        #[key]
        to: PlayerComponent,
        card: CardComponent
    }

    #[derive(Drop, Serde, Introspect)]
    #[dojo::model]
    #[dojo::event]
    struct HasWon {
        #[key]
        winner: PlayerComponent,
        score: u32
    }

    fn dojo_init() {

    }

    #[abi(embed_v0)]
    impl IPlayImpl of IPlay<ContractState> {
        fn distribute_cards(ref world: IWorldDispatcher, dealer_address: ContractAddress) -> Result<(), EnumTxError> {
            return Result::Ok(());
        }

        fn draw(ref world: IWorldDispatcher, dealer_address: ContractAddress) -> Result<(), EnumTxError> {
            // Get the address of the current caller, possibly the player's address.
            let player = get_caller_address();

            // Retrieve the player's current hand from the world.
            let mut player_component = get!(world, player, (PlayerComponent));
            let mut dealer = get!(world, dealer_address, (DealerComponent));

            // Retrieve the card 'on top' of the stack and add it to the player's hand.
            return match dealer.deck.cards.pop_front() {
                Option::Some(card) => {
                    player_component.hand.add(card);

                    set!(world, (player_component));

                    Result::Ok(())
                },
                Option::None(_) => {
                    println!("Error occured in draw(), E: Card popped is None!",);
                    Result::Err(EnumTxError::IncorrectTransaction)
                }
            };
        }

        fn play(ref world: IWorldDispatcher, card: CardComponent) -> Result<(), EnumTxError> {
            return Result::Ok(());
        }

        fn take_from(ref world: IWorldDispatcher, card: CardComponent, recipient: ContractAddress) -> Result<(), EnumTxError> {
            return Result::Ok(());
        }

        fn give_to(ref world: IWorldDispatcher, card: CardComponent, recipient: ContractAddress) -> Result<(), EnumTxError> {
            return Result::Ok(());
        }

        fn swap_with(ref world: IWorldDispatcher, card_given: CardComponent,
            recipient: ContractAddress, card_taken: CardComponent) -> Result<(), EnumTxError> {
            return Result::Ok(());
        }

        fn assign_winner(ref world: IWorldDispatcher, player: PlayerComponent) -> Result<(), EnumTxError> {
            return Result::Ok(());
        }
    }
}

// Internal functions.

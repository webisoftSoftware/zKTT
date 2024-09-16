use zktt::models::{CardComponent, PlayerComponent, EnumTxError};
use starknet::ContractAddress;

#[dojo::interface]
trait IPlay {
    fn distribute_cards(ref world: IWorldDispatcher);
    fn draw(ref world: IWorldDispatcher) -> Result<(), EnumTxError>;
    fn play(ref world: IWorldDispatcher, card: CardComponent) -> Result<(), EnumTxError>;
    fn take_from(ref world: IWorldDispatcher, card: CardComponent, recipient: ContractAddress) -> Result<(), EnumTxError>;
    fn give_to(ref world: IWorldDispatcher, card: CardComponent, recipient: ContractAddress) -> Result<(), EnumTxError>;
    fn swap_with(ref World: IWorldDispatcher, card_given: CardComponent,
        recipient: ContractAddress, card_taken: CardComponent) -> Result<(), EnumTxError>;
}

#[dojo::contract]
mod play {
    use super::IPlay;
    use starknet::get_caller_address;
    use zktt::models::{CardComponent, PlayerComponent, HandComponent, DealerComponent,
     DeckComponent, EnumTxError};

    #[derive(Copy, Drop, Serde)]
    #[dojo::model]
    #[dojo::event]
    struct CardDrew {
        #[key]
        from: Player,
        card: CardComponent
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::model]
    #[dojo::event]
    struct CardPlayed {
        #[key]
        from: Player,
        card: CardComponent
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::model]
    #[dojo::event]
    struct CardMoved {
        #[key]
        from: Player,
        to: Player,
        card: CardComponent
    }

    #[abi(embed_v0)]
    impl IPlayImpl of IPlay<ContractState> {
        fn draw(ref world: IWorldDispatcher) {
            // Get the address of the current caller, possibly the player's address.
            let player = get_caller_address();

            // Retrieve the player's current hand from the world.
            let mut hand = get!(world, player, (HandComponent));

            // Retrive the card 'on top' of the stack and add it to the player's hand.
            let mut dealer = DealerComponent::get(world);
            hand.add(dealer.pop_card());

            set!(world, (HandComponent::new(player, hand)));
        }

        fn play(ref world: IWorldDispatcher, card: CardComponent) {
            // Get the address of the current caller, possibly the player's address.
            let player = get_caller_address();

            // Retrieve the player's current position and moves data from the world.
            let (mut position, mut moves) = get!(world, player, (HandComponent, DeckComponent));

            // Deduct one from the player's remaining moves.
            moves.remaining -= 1;

            // Update the last direction the player moved in.
            moves.last_direction = direction;

            // Calculate the player's next position based on the provided direction.
            let next = next_position(position, direction);

            // Update the world state with the new moves data and position.
            set!(world, (moves, next));
            // Emit an event to the world to notify about the player's move.
            emit!(world, (Played { player, direction }));
        }
    }
}

// Internal functions.

/// Assign a winner when a player has 3 properties in their deck.
fn assign_winner(ref world: IWorldDispatcher, ref player: PlayerComponent) -> () {
   // Retrieve the player's current score from the world and update it.
   let mut player = get!(world, player, (PlayerComponent));
   player.score + 1;

   set!(world, (player));

   // Anounce the winner.
   emit!(world, (HasWon { player }));
}

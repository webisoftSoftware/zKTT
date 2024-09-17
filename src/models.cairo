use starknet::ContractAddress;

////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
/////////////////////////////// COMPONENTS /////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////

#[derive(Drop, Serde, Introspect)]
#[dojo::model]
struct PlayerComponent {
    #[key]
    pub username: felt252,
    pub hand: HandComponent,
    pub deck: DeckComponent,
    pub moves_remaining: u8,
    pub score: u32,
}

#[derive(Drop, Serde, Introspect)]
#[dojo::model]
struct DealerComponent {
    #[key]
    pub dealer_id: ContractAddress,
    pub deck: DeckComponent,
}

#[derive(Drop, Serde, Introspect)]
pub struct HandComponent {
    pub cards: Array<CardComponent>
}

#[derive(Drop, Serde, Introspect)]
pub struct DeckComponent {
    pub cards: Array<CardComponent>
}

#[derive(Copy, Drop, Serde, Introspect)]
#[dojo::model]
pub struct CardComponent {
    #[key]
    pub name: felt252,
    pub description: felt252,
    pub card_category: EnumCardCategory,
    pub value: u8,
    pub rank: u8
}

////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
/////////////////////////////// TRAITS /////////////////////////////////
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////

trait IPlayerComponent {
    fn new(username: felt252, hand: HandComponent, deck: DeckComponent,
        moves_remaining: u8, score: u32) -> PlayerComponent;
}

trait IHandComponent {
    fn new(cards: Array<CardComponent>) -> HandComponent;
    fn add(ref self: HandComponent, card: CardComponent) -> ();
    fn use_card(ref self: HandComponent, card: CardComponent) -> Result<(), EnumTxError>;
}

trait IDeckComponent {
    fn new(cards: Array<CardComponent>) -> DeckComponent;
    fn use_card(ref self: DeckComponent, card: CardComponent) -> Result<(), EnumTxError>;
}

trait ICardComponent {
    fn new(name: felt252, description: felt252, card_category: EnumCardCategory,
            value: u8, rank: u8) -> CardComponent;
    fn compare_rank_with(ref self: CardComponent, field: @CardComponent) -> EnumCardCompare;

}

impl PlayerComponentImpl of IPlayerComponent {
    fn new(username: felt252, hand: HandComponent, deck: DeckComponent,
        moves_remaining: u8, score: u32) -> PlayerComponent {
        return PlayerComponent {
            username: username,
            hand: hand,
            deck: deck,
            moves_remaining: 3,
            score: score,
        };
    }
}

impl HandComponentImpl of IHandComponent {
    fn new(cards: Array<CardComponent>) -> HandComponent {
        return HandComponent {
            cards: cards,
        };
    }

    fn add(ref self: HandComponent, card: CardComponent) -> () {
        self.cards.append(card);
        return ();
    }

    fn use_card(ref self: HandComponent, card: CardComponent) -> Result<(), EnumTxError> {
        if self.cards.is_empty() {
            return Result::Err(EnumTxError::CardNotFound);
        }

        let mut index = 0;
        let mut card_index = 0;
        let mut card_found = false;
        let mut migrated_array = ArrayTrait::<CardComponent>::new();

        while index < self.cards.len() {
            if let Option::Some(current_card) = self.cards.pop_front() {
                migrated_array.append(current_card);
                continue;
            }

            card_index = index;
            index += 1;
        };

        if !card_found {
            return Result::Err(EnumTxError::CardNotFound);
        }

        self.cards = migrated_array;

        return Result::Ok(());
    }
}

impl DeckComponentImpl of IDeckComponent {
    fn new(cards: Array<CardComponent>) -> DeckComponent {
        return DeckComponent {
            cards: cards
        };
    }

    fn use_card(ref self: DeckComponent, card: CardComponent) -> Result<(), EnumTxError> {
        if self.cards.is_empty() {
            return Result::Err(EnumTxError::CardNotFound);
        }

        let mut index = 0;
        let mut card_index = 0;
        let mut card_found = false;
        let mut migrated_array = ArrayTrait::<CardComponent>::new();

        while index < self.cards.len() {
            if let Option::Some(current_card) = self.cards.pop_front() {
                migrated_array.append(current_card);
                continue;
            }

            card_index = index;
            index += 1;
        };

        if !card_found {
            return Result::Err(EnumTxError::CardNotFound);
        }

        self.cards = migrated_array;

        return Result::Ok(());
    }
}

impl CardComponentImpl of ICardComponent {
    fn new(name: felt252, description: felt252, card_category: EnumCardCategory,
        value: u8, rank: u8) -> CardComponent {
        return CardComponent {
            name: name,
            description: description,
            card_category: card_category,
            value: value,
            rank: rank
        };
    }
    
    fn compare_rank_with(ref self: CardComponent, field: @CardComponent) -> EnumCardCompare {
        if self.rank > *field.rank {
            return EnumCardCompare::Bigger;
        }
        
        if self.rank < *field.rank {
            return EnumCardCompare::Smaller;
        }
        
        return EnumCardCompare::Equal;
    }
}

///////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////
/////////////////////////////// ENUMS /////////////////////////////////
///////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////

#[derive(Copy, Drop, Serde, PartialEq, Introspect)]
enum EnumTxError {
    IncorrectTransaction: (),
    InvalidMove: (),
    CardNotFound: (),
    UnknownPlayer: (),
    LobbyFull: (),
    LobbyDoesNotExist: ()
}

#[derive(Copy, Drop, Serde, PartialEq, Introspect)]
enum EnumCardCompare {
    Smaller: (),
    Equal: (),
    Bigger: ()
}

#[derive(Copy, Drop, Serde, PartialEq, Introspect)]
enum EnumCardCategory {
    Cash: (),
    Property: (),
    Special: ()
}


///////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////
/////////////////////////////// TESTS /////////////////////////////////
///////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////

#[cfg(test)]
mod tests {
    use super::{CardComponent, Card, PlayerComponent, EnumCardCategory};

    #[test]
    fn test_is_equal() {
        let player = PlayerComponent::new("0xffffffffff", "nami2301", 3, 0);
        let card1 = CardComponent::new(player,
            name: "1M".to_string(),
            description: "1 Million Dollars".to_string(),
            card_type: EnumCardCategory::Cash,
            value: 1,
            rank: 0);
        
        let card2 = CardComponent::new(player,
            name: "2M".to_string(),
            description: "2 Million Dollars".to_string(),
            card_type: EnumCardCategory::Cash,
            value: 2,
            rank: 0);
        
        assert(card1.compare_rank_with(card2), 'Ranks should be equal');
    }
}

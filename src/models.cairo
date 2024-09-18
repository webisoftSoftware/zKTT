use starknet::ContractAddress;

////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
/////////////////////////////// COMPONENTS /////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////

#[derive(Drop, Serde)]
#[dojo::model]
struct PlayerComponent {
    #[key]
    ent_username: felt252,
    #[key]
    ent_deck: Array<CardComponent>,
    #[key]
    ent_hand: Array<CardComponent>,
    pub moves_remaining: u8,
    pub score: u32
}

#[derive(Drop, Serde)]
#[dojo::model]
pub struct CardComponent {
    #[key]
    pub ent_category: EnumCardCategory,
    pub total_left: u8
}

#[derive(Drop, Serde)]
#[dojo::model]
pub struct BlockchainComponent {
    #[key]
    pub ent_name: felt252,
    pub value: u256
}

#[derive(Drop, Serde)]
#[dojo::model]
pub struct GasFeeComponent {
    #[key]
    pub ent_name: felt252,
    pub first_blockchains_affected: BlockchainComponent,
    pub second_blockchain_affected: Option<BlockchainComponent>,
    pub value: u256,
    pub fees: u256
}

#[derive(Drop, Serde)]
#[dojo::model]
pub struct SpecialComponent {
    #[key]
    pub ent_name: felt252,
    pub value: u256
}

////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
/////////////////////////////// TRAITS /////////////////////////////////
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////

trait IPlayer {
    fn new(username: felt252, deck: Array<CardComponent>, hand: Array<CardComponent>,
        moves_remaining: u8, score: u32) -> PlayerComponent;
    fn add_to_hand(ref self: PlayerComponent, card: CardComponent) -> Result<(), EnumMoveError>;
    fn use_card(ref self: PlayerComponent, card: CardComponent) -> Result<(), EnumMoveError>;
}

trait ICard {
    fn new(category: EnumCardCategory, total_left: u8) -> CardComponent;
    fn is_equal(self: @CardComponent, other: @CardComponent) -> bool;
}

trait IAction {
    fn apply_action(self: @EnumCardCategory) -> Result<(), EnumMoveError>;
}

impl PlayerImpl of IPlayer {
    fn new(username: felt252, deck: Array<CardComponent>, hand: Array<CardComponent>,
            moves_remaining: u8, score: u32) -> PlayerComponent {
        return PlayerComponent {
            ent_username: username,
            ent_deck: deck,
            ent_hand: hand,
            moves_remaining: moves_remaining,
            score: score,
        };
    }

    fn add_to_hand(ref self: PlayerComponent, card: CardComponent) -> Result<(), EnumMoveError> {
        if self.ent_hand.len() > 7 && self.moves_remaining == 1 {
            return Result::Err(EnumMoveError::TooManyCardsHeld);
        }

        self.ent_hand.append(card);
        self.moves_remaining -= 1;
        return Result::Ok(());
    }

    fn use_card(ref self: PlayerComponent, card: CardComponent) -> Result<(), EnumMoveError> {
        if self.ent_hand.is_empty() {
            return Result::Err(EnumMoveError::CardNotFound);
        }

        let mut index = 0;
        let mut card_index = 0;
        let mut card_found = false;
        let mut migrated_array = ArrayTrait::<CardComponent>::new();

        while index < self.ent_hand.len() {
            if let Option::Some(current_card) = self.ent_hand.pop_front() {
                migrated_array.append(current_card);
                continue;
            }

            card_index = index;
            index += 1;
        };

        if !card_found {
            return Result::Err(EnumMoveError::CardNotFound);
        }

        self.ent_hand = migrated_array;
        self.moves_remaining -= 1;
        return Result::Ok(());
    }
}

impl CardImpl of ICard {
    fn new(category: EnumCardCategory, total_left: u8) -> CardComponent {
        return CardComponent {
            ent_category: category,
            total_left: total_left
        };
    }

    fn is_equal(self: @CardComponent, other: @CardComponent) -> bool {
        return match (self.ent_category, other.ent_category) {
            (EnumCardCategory::Eth(our_value), EnumCardCategory::Eth(their_value)) => our_value == their_value,
            (EnumCardCategory::GasFee(our_component), EnumCardCategory::GasFee(their_component)) =>
                our_component.ent_name == their_component.ent_name && our_component.value == their_component.value,
            (EnumCardCategory::Blockchain(our_component), EnumCardCategory::Blockchain(their_component)) =>
                our_component.ent_name == their_component.ent_name && our_component.value == their_component.value,
            (EnumCardCategory::Special(our_component), EnumCardCategory::Special(their_component)) =>
                our_component.ent_name == their_component.ent_name && our_component.value == their_component.value,
            _ => false
        };
    }
}

impl IActionImpl of IAction {
    fn apply_action(self: @EnumCardCategory) -> Result<(), EnumMoveError> {
        match self {
            EnumCardCategory::Eth(_value) => {},
            EnumCardCategory::GasFee(_component) => {},
            EnumCardCategory::Blockchain(_component) => {},
            EnumCardCategory::Special(_component) => {},
            _ => { return Result::Err(EnumMoveError::InvalidCardCategory); }
        };

        return Result::Ok(());
    }
}

///////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////
/////////////////////////////// ENUMS /////////////////////////////////
///////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////

#[derive(Copy, Drop, Serde, PartialEq, Introspect)]
enum EnumMoveError {
    TooManyCardsHeld: (),
    CardNotFound: (),
    InvalidCardCategory: ()
}

#[derive(Drop, Serde, Introspect)]
enum EnumCardCategory {
    Eth: u256,
    GasFee: GasFeeComponent,
    Blockchain: BlockchainComponent,
    Special: SpecialComponent
}


///////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////
/////////////////////////////// TESTS /////////////////////////////////
///////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////

#[cfg(test)]
mod tests {}

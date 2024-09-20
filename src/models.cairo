use starknet::ContractAddress;
use core::fmt::{Display, Formatter, Error};

////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
/////////////////////////////// COMPONENTS /////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////

#[derive(Drop, Serde)]
#[dojo::model]
struct GameComponent {
    #[key]
    pub seed: felt252,
    pub state: EnumGameState,
    pub players: Array<PlayerComponent>,
    pub deck_on_board: CardPileComponent
}

#[derive(Drop, Serde)]
#[dojo::model]
struct CardPileComponent {
    #[key]
    seed: felt252,
    cards: Array<CardComponent>,
}

#[derive(Drop, Serde)]
#[dojo::model]
struct PlayerComponent {
    #[key]
    ent_address: ContractAddress,
    username: ByteArray,
    deck: Array<CardComponent>,
    hand: Array<CardComponent>,
    asset_groups: Array<CardComponent>,
    moves_remaining: u8,
    has_won: bool,
    score: u32
}

#[derive(Drop, Serde, Introspect)]
pub struct CardComponent {
    category: EnumCardCategory,
    total_left: u8
}

#[derive(Drop, Serde)]
#[dojo::model]
pub struct BlockchainComponent {
    #[key]
    ent_name: ByteArray,
    value: u256
}

#[derive(Drop, Serde)]
#[dojo::model]
pub struct GasFeeComponent {
    #[key]
    ent_name: ByteArray,
    first_blockchain_affected: BlockchainComponent,
    second_blockchain_affected: Option<BlockchainComponent>,
    value: u256,
    fees: u256
}

#[derive(Drop, Serde)]
#[dojo::model]
pub struct SpecialComponent {
    #[key]
    ent_name: ByteArray,
    value: u256
}

/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////// DISPLAY /////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////

impl PlayerDisplay of Display<PlayerComponent> {
    fn fmt(self: @PlayerComponent, ref f: Formatter) -> Result<(), Error> {
        let str: ByteArray = format!("Has won: {0}\nMoves remaining: {1}\nScore: {2}",
         *self.has_won, *self.moves_remaining, *self.score);
        f.buffer.append(@str);

        let mut index = 0;
        let str: ByteArray = format!("\nDeck:\n");
        f.buffer.append(@str);

        while index < self.deck.len() {
            if let Option::Some(card) = self.deck.get(index) {
                let str: ByteArray = format!("{0}", card.unbox());
                f.buffer.append(@str);
            }
        };

        let mut index = 0;
        let str: ByteArray = format!("\nHand:\n");
        f.buffer.append(@str);

        while index < self.hand.len() {
            if let Option::Some(card) = self.hand.get(index) {
                let str: ByteArray = format!("{0}", card.unbox());
                f.buffer.append(@str);
            }
        };

        let mut index = 0;
        let str: ByteArray = format!("\nAsset Groups:\n");
        f.buffer.append(@str);

        while index < self.asset_groups.len() {
            if let Option::Some(card) = self.asset_groups.get(index) {
                let str: ByteArray = format!("Asset Group {0}: {1}", index, card.unbox());
                f.buffer.append(@str);
            }
        };

        return Result::Ok(());
    }
}

impl CardDisplay of Display<CardComponent> {
    fn fmt(self: @CardComponent, ref f: Formatter) -> Result<(), Error> {
        let str: ByteArray = format!("Category: {0}, Copies Left: {1}", self.category,
         *self.total_left);
        f.buffer.append(@str);
        return Result::Ok(());
    }
}

impl BlockchainDisplay of Display<BlockchainComponent> {
    fn fmt(self: @BlockchainComponent, ref f: Formatter) -> Result<(), Error> {
        let str: ByteArray = format!("Name: {0}, Value: {1}", self.ent_name, *self.value);
        f.buffer.append(@str);
        return Result::Ok(());
    }
}

impl GasFeeDisplay of Display<GasFeeComponent> {
    fn fmt(self: @GasFeeComponent, ref f: Formatter) -> Result<(), Error> {
        if let Option::Some(second_bc_affected) = self.second_blockchain_affected {
            let str: ByteArray = format!("Name: {0}, First Targeted Blockchain: {1}, Second (opt)
                Targeted Blockchain: {2}, Value: {3}, Fees: {4}",
                self.ent_name, self.first_blockchain_affected, second_bc_affected, *self.value,
                *self.fees);
            f.buffer.append(@str);
            return Result::Ok(());
        }

        let str: ByteArray = format!("Name: {0}, First Targeted Blockchain: {1}, Value: {2}\n
            Fees: {3}", self.ent_name, self.first_blockchain_affected, *self.value, *self.fees);
        f.buffer.append(@str);
        return Result::Ok(());
    }
}

impl SpecialDisplay of Display<SpecialComponent> {
    fn fmt(self: @SpecialComponent, ref f: Formatter) -> Result<(), Error> {
        let str: ByteArray = format!("Name: {0}, Value: {1}", self.ent_name, *self.value);
        f.buffer.append(@str);
        return Result::Ok(());
    }
}

impl CardCategoryDisplay of Display<EnumCardCategory> {
    fn fmt(self: @EnumCardCategory, ref f: Formatter) -> Result<(), Error> {
        match self {
            EnumCardCategory::Eth(value) => {
                let str: ByteArray = format!("Eth: ({value})");
                f.buffer.append(@str);
            },
            EnumCardCategory::GasFee(component) => {
                let str: ByteArray = format!("GasFee: ({component})");
                f.buffer.append(@str);
            },
            EnumCardCategory::Blockchain(component) => {
                let str: ByteArray = format!("Blockchain: ({component})");
                f.buffer.append(@str);
            },
            EnumCardCategory::Special(component) => {
                let str: ByteArray = format!("Special: ({component})");
                f.buffer.append(@str);
            },
            _ => {}
        };
        return Result::Ok(());
    }
}

////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
/////////////////////////////// TRAITS /////////////////////////////////
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////

#[generate_trait]
impl GameImpl of IGameComponent {
    fn remove_player(ref self: GameComponent, username: @ByteArray) -> Option<PlayerComponent> {
        // TODO: Impl function to check if the player exists and remove the player and create a new array.
        return Option::None;
    }
}

#[generate_trait]
impl PlayerImpl of IPlayer {
    fn new(ent_address: ContractAddress, username: ByteArray, deck: Array<CardComponent>,
         hand: Array<CardComponent>, asset_groups: Array<CardComponent>) -> PlayerComponent {
        return PlayerComponent {
            ent_address: ent_address,
            username: username,
            deck: deck,
            hand: hand,
            asset_groups: asset_groups,
            has_won: false,
            moves_remaining: 3,
            score: 0,
        };
    }

    fn add_to_hand(ref self: PlayerComponent, card: CardComponent) -> Result<(), EnumMoveError> {
        if self.hand.len() > 7 && self.moves_remaining == 1 {
            return Result::Err(EnumMoveError::TooManyCardsHeld);
        }

        if self.moves_remaining == 0 {
            return Result::Err(EnumMoveError::NotEnoughMoves);
        }

        self.hand.append(card);
        self.moves_remaining -= 1;
        return Result::Ok(());
    }

    fn use_card(ref self: PlayerComponent, card: CardComponent) -> Result<(), EnumMoveError> {
        if self.hand.is_empty() {
            return Result::Err(EnumMoveError::CardNotFound);
        }

        if self.moves_remaining == 0 {
            return Result::Err(EnumMoveError::NotEnoughMoves);
        }

        let mut index = 0;
        let mut card_index = 0;
        let mut card_found = false;
        let mut migrated_array = ArrayTrait::<CardComponent>::new();

        while index < self.hand.len() {
            if let Option::Some(current_card) = self.hand.pop_front() {
                migrated_array.append(current_card);
                continue;
            }

            card_index = index;
            index += 1;
        };

        if !card_found {
            return Result::Err(EnumMoveError::CardNotFound);
        }

        self.hand = migrated_array;
        self.moves_remaining -= 1;
        return Result::Ok(());
    }
}

#[generate_trait]
impl CardImpl of ICard {
    fn new(category: EnumCardCategory, total_left: u8) -> CardComponent {
        return CardComponent {
            category: category,
            total_left: total_left
        };
    }

    fn is_equal(self: @CardComponent, other: @CardComponent) -> bool {
        return match (self.category, other.category) {
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

#[generate_trait]
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
enum EnumGameState {
    WaitingForPlayers: (),
    Started: (),
    Ended: ()
}

#[derive(Copy, Drop, Serde, PartialEq, Introspect)]
enum EnumMoveError {
    TooManyCardsHeld: (),
    CardNotFound: (),
    InvalidCardCategory: (),
    NotEnoughMoves: ()
}

#[derive(Drop, Serde, Introspect)]
enum EnumCardCategory {
    Eth: u256,
    GasFee: GasFeeComponent,
    Blockchain: BlockchainComponent,
    Special: SpecialComponent
}
